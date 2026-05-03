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
