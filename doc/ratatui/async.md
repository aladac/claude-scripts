# Ratatui Async Operations

Handle slow operations without freezing the UI using Tokio.

## Tokio Integration

Ratatui works well with Tokio for async operations.

```toml
[dependencies]
ratatui = "0.29"
crossterm = "0.28"
tokio = { version = "1", features = ["full"] }
```

---

## Basic Async Pattern

```rust
use tokio::sync::mpsc;
use std::time::Duration;

enum AppEvent {
    Input(crossterm::event::Event),
    Tick,
    DataLoaded(Vec<String>),
}

struct App {
    data: Vec<String>,
    loading: bool,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let mut terminal = ratatui::init();
    let result = run(&mut terminal).await;
    ratatui::restore();
    result
}

async fn run(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    let (tx, mut rx) = mpsc::unbounded_channel::<AppEvent>();
    let mut app = App { data: vec![], loading: true };

    // Spawn input handler
    let tx_input = tx.clone();
    tokio::spawn(async move {
        loop {
            if crossterm::event::poll(Duration::from_millis(100)).unwrap() {
                if let Ok(event) = crossterm::event::read() {
                    let _ = tx_input.send(AppEvent::Input(event));
                }
            }
        }
    });

    // Spawn data loader
    let tx_data = tx.clone();
    tokio::spawn(async move {
        let data = fetch_data().await;
        let _ = tx_data.send(AppEvent::DataLoaded(data));
    });

    // Main loop
    loop {
        terminal.draw(|frame| app.render(frame))?;

        if let Some(event) = rx.recv().await {
            match event {
                AppEvent::Input(Event::Key(key)) => {
                    if key.code == KeyCode::Char('q') {
                        break;
                    }
                }
                AppEvent::DataLoaded(data) => {
                    app.data = data;
                    app.loading = false;
                }
                _ => {}
            }
        }
    }

    Ok(())
}

async fn fetch_data() -> Vec<String> {
    // Simulate async fetch
    tokio::time::sleep(Duration::from_secs(2)).await;
    vec!["Item 1".into(), "Item 2".into()]
}
```

---

## Channel-Based Architecture

```rust
use tokio::sync::mpsc::{self, UnboundedSender, UnboundedReceiver};

// Messages from background tasks to UI
enum Message {
    DataLoaded(Vec<Item>),
    Error(String),
    Progress(f64),
}

// Commands from UI to background
enum Command {
    LoadData,
    Cancel,
}

struct App {
    tx: UnboundedSender<Command>,
    rx: UnboundedReceiver<Message>,
    state: AppState,
}

impl App {
    fn new() -> Self {
        let (cmd_tx, mut cmd_rx) = mpsc::unbounded_channel::<Command>();
        let (msg_tx, msg_rx) = mpsc::unbounded_channel::<Message>();

        // Background worker
        tokio::spawn(async move {
            while let Some(cmd) = cmd_rx.recv().await {
                match cmd {
                    Command::LoadData => {
                        let result = fetch_data().await;
                        let _ = msg_tx.send(Message::DataLoaded(result));
                    }
                    Command::Cancel => break,
                }
            }
        });

        Self {
            tx: cmd_tx,
            rx: msg_rx,
            state: AppState::default(),
        }
    }

    fn load_data(&self) {
        let _ = self.tx.send(Command::LoadData);
    }

    fn poll_messages(&mut self) {
        while let Ok(msg) = self.rx.try_recv() {
            match msg {
                Message::DataLoaded(data) => self.state.data = data,
                Message::Error(e) => self.state.error = Some(e),
                Message::Progress(p) => self.state.progress = p,
            }
        }
    }
}
```

---

## Non-Blocking Event Loop

```rust
use std::time::{Duration, Instant};

async fn run(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    let tick_rate = Duration::from_millis(100);
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|frame| app.render(frame))?;

        // Poll messages from background tasks
        app.poll_messages();

        // Non-blocking event check
        let timeout = tick_rate.saturating_sub(last_tick.elapsed());
        if crossterm::event::poll(timeout)? {
            if let Event::Key(key) = crossterm::event::read()? {
                if key.code == KeyCode::Char('q') {
                    break;
                }
                app.handle_key(key);
            }
        }

        if last_tick.elapsed() >= tick_rate {
            app.tick();  // Update animations, timers
            last_tick = Instant::now();
        }
    }

    Ok(())
}
```

---

## Spawning Shell Commands

```rust
use tokio::process::Command;

async fn run_command(cmd: &str) -> Result<String, std::io::Error> {
    let output = Command::new("sh")
        .arg("-c")
        .arg(cmd)
        .output()
        .await?;

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

// In background task
tokio::spawn(async move {
    match run_command("git status").await {
        Ok(output) => tx.send(Message::CommandOutput(output)),
        Err(e) => tx.send(Message::Error(e.to_string())),
    }
});
```

---

## HTTP Requests

```rust
use reqwest;

async fn fetch_api_data() -> Result<Vec<Item>, reqwest::Error> {
    let response = reqwest::get("https://api.example.com/items")
        .await?
        .json::<Vec<Item>>()
        .await?;
    Ok(response)
}

// Spawn from UI
let tx = tx.clone();
tokio::spawn(async move {
    match fetch_api_data().await {
        Ok(data) => tx.send(Message::DataLoaded(data)),
        Err(e) => tx.send(Message::Error(e.to_string())),
    }
});
```

---

## Progress Updates

```rust
async fn download_with_progress(
    url: &str,
    tx: UnboundedSender<Message>,
) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let response = reqwest::get(url).await?;
    let total = response.content_length().unwrap_or(0);
    let mut downloaded: u64 = 0;
    let mut data = Vec::new();

    let mut stream = response.bytes_stream();
    while let Some(chunk) = stream.next().await {
        let chunk = chunk?;
        downloaded += chunk.len() as u64;
        data.extend_from_slice(&chunk);

        let progress = if total > 0 {
            downloaded as f64 / total as f64
        } else {
            0.0
        };
        let _ = tx.send(Message::Progress(progress));
    }

    Ok(data)
}
```

---

## Cancellation

```rust
use tokio_util::sync::CancellationToken;

struct App {
    cancel_token: CancellationToken,
}

impl App {
    fn start_task(&self) {
        let token = self.cancel_token.clone();
        let tx = self.tx.clone();

        tokio::spawn(async move {
            tokio::select! {
                _ = token.cancelled() => {
                    // Task was cancelled
                }
                result = long_running_task() => {
                    let _ = tx.send(Message::TaskComplete(result));
                }
            }
        });
    }

    fn cancel(&self) {
        self.cancel_token.cancel();
    }
}
```

---

## Multiple Background Tasks

```rust
struct TaskManager {
    tasks: HashMap<TaskId, JoinHandle<()>>,
    cancel_tokens: HashMap<TaskId, CancellationToken>,
}

impl TaskManager {
    fn spawn<F>(&mut self, id: TaskId, future: F)
    where
        F: Future<Output = ()> + Send + 'static,
    {
        let token = CancellationToken::new();
        self.cancel_tokens.insert(id, token.clone());

        let handle = tokio::spawn(async move {
            tokio::select! {
                _ = token.cancelled() => {}
                _ = future => {}
            }
        });

        self.tasks.insert(id, handle);
    }

    fn cancel(&mut self, id: TaskId) {
        if let Some(token) = self.cancel_tokens.get(&id) {
            token.cancel();
        }
    }

    fn cancel_all(&mut self) {
        for token in self.cancel_tokens.values() {
            token.cancel();
        }
    }
}
```

---

## Pattern Summary

| Pattern | Use Case |
|---------|----------|
| `mpsc` channel | UI ↔ background communication |
| `tokio::spawn` | Background tasks |
| `CancellationToken` | Graceful task cancellation |
| `tokio::select!` | Wait for multiple futures |
| `try_recv()` | Non-blocking message polling |
