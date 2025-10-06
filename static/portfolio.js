// LogManager to handle output forwarding between console and terminal
export const LogManager = {
  outputHandlers: {
    onStdout: console.log,
    onStderr: console.error,
  },
  setOutputHandlers(handlers) {
    this.outputHandlers = handlers;
  },
  stdout(text) {
    this.outputHandlers.onStdout(text);
  },
  stderr(text) {
    this.outputHandlers.onStderr(text);
  },
};

// Initialize terminal component after layout is loaded
export async function initializeTerminal(terminalElement) {
  if (!terminalElement) {
    console.warn("Terminal element not found");
    return;
  }

  // Initialize xterm with light theme
  const term = new Terminal({
    theme: {
      background: "#ffffff",
      foreground: "#000000",
      cursor: "#000000",
      selection: "#d4d4d4",
    },
    rows: 30,
    cols: 120,
    fontSize: 14,
    fontFamily: 'Monaco, Menlo, "Ubuntu Mono", monospace',
    convertEol: true, // auto replace \n -> \r\n
  });

  term.open(terminalElement);

  window.terminal = term;

  // Configure LogManager to output to terminal
  LogManager.setOutputHandlers({
    onStdout: (text) => displayOutput(text, { isError: false }),
    onStderr: (text) => displayOutput(text, { isError: true }),
  });
  // XXX maybe this loops ?

  // Display welcome message
  displayWelcomeMessage();

  // Handle terminal input
  term.onKey(async (key) => {
    let text = key.key;
    const keyCode = key.domEvent.keyCode;

    // Ignore certain keys that should be handled by the shell
    const IGNORED_KEYS = [38, 40, 9]; // Arrow up, arrow down, tab
    if (IGNORED_KEYS.includes(keyCode)) {
      text = "";
    }

    try {
      await window.popcorn.call(
        {
          command: "terminal_input",
          text: text,
        },
        {
          timeoutMs: 10_000,
        },
      );
    } catch (error) {
      displayOutput(error.toString(), { isError: true });
    }
    console.log("back");
  });

  return term;
}

function displayOutput(text, { isError }) {
  if (isError) {
    text = "\x1b[31m" + text + "\x1b[0m\n\r";
  }
  if (window.terminal) {
    window.terminal.write(text);
  }
}

function displayWelcomeMessage() {
  const welcomeText = `
\x1b[1;35m╔══════════════════════════════════════════════════════════════════════════════╗
║                          Welcome to Marcin's Portfolio                       ║
║                                                                              ║
║          Portfolio running on AtomVM + Popcorn in your browser!              ║
║                                                                              ║
║    This terminal is connected to a live Elixir BEAM instance.                ║
║    Try typing some Elixir commands or explore the portfolio windows above.   ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝\x1b[0m

\x1b[1;36mElixir Interactive Shell (Portfolio Edition)\x1b[0m
\x1b[33mType help() for available commands.\x1b[0m

iex(1)> `;

  if (window.terminal) {
    window.terminal.write(welcomeText);
  }
}
