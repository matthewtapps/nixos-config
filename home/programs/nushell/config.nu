$env.config = ($env.config | merge {
    show_banner: false
    edit_mode: vi
    cursor_shape: ($env.config.cursor_shape | merge {
        vi_insert: "line"
        vi_normal: "block"
    })
    history: ($env.config.history | merge {
        max_size: 10000000
        sync_on_enter: true
        file_format: "sqlite"
    })
    completions: ($env.config.completions | merge {
        case_sensitive: false
        quick: true
        algorithm: "fuzzy"
    })
})

$env.config.keybindings = ($env.config.keybindings | append [
    # ctrl+space: accept history hint (ghost text) — like zsh autosuggest-accept
    {
        name: accept_history_hint
        modifier: control
        keycode: space
        mode: [emacs vi_insert]
        event: { send: HistoryHintComplete }
    }
    # ctrl+p/ctrl+n: history navigation in insert mode (emacs-style)
    {
        name: history_prev
        modifier: control
        keycode: char_p
        mode: [emacs vi_insert]
        event: { send: Up }
    }
    {
        name: history_next
        modifier: control
        keycode: char_n
        mode: [emacs vi_insert]
        event: { send: Down }
    }
    # ctrl+r: fuzzy history search (explicit binding for vi insert mode)
    {
        name: history_search
        modifier: control
        keycode: char_r
        mode: [emacs vi_insert vi_normal]
        event: { send: SearchHistory }
    }
    # ctrl+w / ctrl+backspace: delete word backward
    {
        name: delete_word_backward
        modifier: control
        keycode: char_w
        mode: [emacs vi_insert]
        event: { edit: BackspaceWord }
    }
    {
        name: delete_word_ctrl_backspace
        modifier: control
        keycode: char_h
        mode: [emacs vi_insert]
        event: { edit: BackspaceWord }
    }
])

alias v = nvim
alias la = ls -a
alias lg = lazygit
alias ldo = lazydocker
alias aliases = scope aliases

def --env nixc [] {
    let prev = $env.PWD
    cd ~/nixos-config
    nvim
    cd $prev
}

def --wrapped nix [...args] {
    let subcmd = ($args | get -o 0)
    let has_command = ($args | any { |a| $a == "--command" or $a == "-c" })
    if ($subcmd in ["shell" "develop"]) and (not $has_command) {
        ^nix ...$args --command nu
    } else {
        ^nix ...$args
    }
}

def vup [] {
    let cache = $"($env.HOME)/.cache/version-checks"
    mut found = false

    if (which node | is-not-empty) {
        let f = $"($cache)/node.latest"
        if ($f | path exists) {
            let current = (^node --version | str trim | str replace "v" "")
            let latest = (open $f | str trim)
            if $current != $latest {
                print $"node     ($current) → ($latest)"
                $found = true
            }
        }
    }

    if (which python3 | is-not-empty) {
        let f = $"($cache)/python.latest"
        if ($f | path exists) {
            let current = (^python3 --version | str trim | split words | last)
            let latest = (open $f | str trim)
            if $current != $latest {
                print $"python   ($current) → ($latest)"
                $found = true
            }
        }
    }

    if (which rustc | is-not-empty) {
        let f = $"($cache)/rust.latest"
        if ($f | path exists) {
            let current = (^rustc --version | str trim | split words | get 1)
            let latest = (open $f | str trim)
            if $current != $latest {
                print $"rust     ($current) → ($latest)"
                $found = true
            }
        }
    }

    if (which go | is-not-empty) {
        let f = $"($cache)/go.latest"
        if ($f | path exists) {
            let current = (^go version | str trim | split words | get 2 | str replace "go" "")
            let latest = (open $f | str trim)
            if $current != $latest {
                print $"go       ($current) → ($latest)"
                $found = true
            }
        }
    }

    if not $found {
        print "All language runtimes up to date."
    }
}

# Git repo overview report (https://piechowski.io/post/git-commands-before-reading-code/)
def git-overview [] {
    let check = (^git rev-parse --is-inside-work-tree | complete)
    if $check.exit_code != 0 {
        print "Not a git repository."
        return
    }

    let repo = (^git rev-parse --show-toplevel | str trim | path basename)
    let sep = "────────────────────────────────────────"
    let bold = (ansi attr_bold)
    let cyan = (ansi cyan)
    let reset = (ansi reset)

    print ""
    print $"($bold)($cyan)Git Overview: ($repo)($reset)"

    print ""
    print $"($bold)($cyan)($sep)($reset)"
    print $"($bold)Most Modified Files \(past year\)($reset)"
    print $"($cyan)($sep)($reset)"
    ^git log --format=format: --name-only --since="1 year ago"
    | lines
    | where {|f| ($f | str trim) != "" }
    | uniq --count
    | sort-by --reverse count
    | first 20
    | each {|row| print $"  ($row.count) ($row.value)" }
    | ignore

    print ""
    print $"($bold)($cyan)($sep)($reset)"
    print $"($bold)All Contributors \(by commits\)($reset)"
    print $"($cyan)($sep)($reset)"
    ^git shortlog -sn --no-merges HEAD

    print ""
    print $"($bold)($cyan)($sep)($reset)"
    print $"($bold)Recent Contributors \(past 6 months\)($reset)"
    print $"($cyan)($sep)($reset)"
    ^git shortlog -sn --no-merges --since="6 months ago" HEAD

    print ""
    print $"($bold)($cyan)($sep)($reset)"
    print $"($bold)Most Bug-Fixed Files \(past year\)($reset)"
    print $"($cyan)($sep)($reset)"
    ^git log -i -E --grep="fix|bug|broken" --name-only --format=""
    | lines
    | where {|f| ($f | str trim) != "" }
    | uniq --count
    | sort-by --reverse count
    | first 20
    | each {|row| print $"  ($row.count) ($row.value)" }
    | ignore

    print ""
    print $"($bold)($cyan)($sep)($reset)"
    print $"($bold)Commit Velocity \(monthly\)($reset)"
    print $"($cyan)($sep)($reset)"
    let monthly = (
        ^git log --format="%ad" --date=format:"%Y-%m"
        | lines
        | uniq --count
        | sort-by value
    )
    if ($monthly | is-empty) {
        print "  No commits found"
    } else {
        let max = ($monthly | get count | math max)
        let width = 30
        for row in $monthly {
            let raw = ($row.count * $width / $max | math round)
            let len = (if $raw < 1 { 1 } else { $raw })
            let pad_w = ($width - $len)
            let bar = (0..<$len | each {|_| "█" } | str join "")
            let pad = (0..<$pad_w | each {|_| " " } | str join "")
            print $"  ($row.value)  ($cyan)($bar)($reset)($pad) ($row.count)"
        }
    }

    print ""
    print $"($bold)($cyan)($sep)($reset)"
    print $"($bold)Emergency Commits \(past year\)($reset)"
    print $"($cyan)($sep)($reset)"
    let emergency = (
        ^git log --oneline --since="1 year ago"
        | lines
        | where {|line| $line =~ '(?i)revert|hotfix|emergency|rollback' }
    )
    if ($emergency | is-empty) {
        print "  None found"
    } else {
        for line in $emergency { print $"  ($line)" }
    }

    print ""
}
