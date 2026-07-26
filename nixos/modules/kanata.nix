{ ... }:
{
  # Home-row modifier for Herdr (see home/programs/herdr), which has no
  # hold-vs-tap of its own. kanata makes `f` and `j` tap-hold keys:
  #   tap  f/j  -> the letter
  #   hold f/j  -> momentary "herdr" layer emitting Herdr's `ctrl+b <key>` prefix
  # Both keys enter the same layer, so hold with the hand opposite the action key
  # (same-finger chords are impossible).
  #
  # System-wide: every f/j is subject to hold detection. The two 200s per
  # tap-hold-release are (tap-timeout, hold-timeout) ms — lower hold-timeout if
  # sluggish, raise it if normal keypresses are swallowed. No `devices` listed,
  # so kanata grabs every keyboard.
  services.kanata = {
    enable = true;
    keyboards.default = {
      # process-unmapped-keys: any key not in defsrc passes straight through, so
      # only the keys we explicitly remap are touched.
      # concurrent-tap-hold: allow a tap-hold key to resolve while another key is
      # already down — smoother fast typing across the `f` key.
      extraDefCfg = ''
        process-unmapped-keys yes
        concurrent-tap-hold yes
      '';

      config = ''
        (defalias
          ;; hold -> herdr layer; tap -> the letter. Both keys enter one layer.
          hrf (tap-hold-release 200 200 f (layer-while-held herdr))
          hrj (tap-hold-release 200 200 j (layer-while-held herdr))

          ;; Prefix + plain key (C-b <key>), matching Herdr's prefix bindings.
          ;; Ctrl+b survives terminals; ctrl+alt would leak to the shell as Meta.
          ph (macro C-b h)  pj (macro C-b j)  pk (macro C-b k)  pl (macro C-b l)
          pv (macro C-b v)  ps (macro C-b s)  pc (macro C-b c)  pn (macro C-b n)
          pp (macro C-b p)  pq (macro C-b q)  py (macro C-b y)  pw (macro C-b w)
          pg (macro C-b g)  po (macro C-b o)  pe (macro C-b e)  pr (macro C-b r)
          pb (macro C-b b)  px (macro C-b x)  pz (macro C-b z)  pd (macro C-b d)

          ;; Shift-family: prefix + shifted key (C-b S-<key>), via the herdr-shift
          ;; sublayer so kanata emits the shift itself (raw OS shift would leak).
          sh (macro C-b S-h)  sj (macro C-b S-j)  sk (macro C-b S-k)  sl (macro C-b S-l)
          sn (macro C-b S-n)  sw (macro C-b S-w)  st (macro C-b S-t)  sp (macro C-b S-p)
          sd (macro C-b S-d)  sg (macro C-b S-g)  sr (macro C-b S-r)  ss (macro C-b S-s)
          sx (macro C-b S-x)  so (macro C-b S-o)  sb (macro C-b S-b)

          ;; Cycle spaces: prefix + [ / ].
          wsp (macro C-b lbrc)  wsn (macro C-b rbrc)

          ;; shift enters herdr-shift; kanata consumes it so no raw shift leaks.
          ;; Press f/j BEFORE shift, else shift is a raw OS shift in the base layer.
          sft (layer-while-held herdr-shift))

        ;; Only f/j are tap-hold; every other key is transparent in base. lsft/rsft
        ;; are listed so the herdr layer can capture shift.
        (defsrc
          f j h k l v s c n p q y w g o e r b x z d / t lbrc rbrc lsft rsft)

        (deflayer base
          @hrf @hrj _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _)

        ;; f/j held: prefix + plain key. [ / ] cycle spaces, shift -> herdr-shift,
        ;; / -> ctrl+alt+/ (Hyprland cheatsheet bind).
        (deflayer herdr
          _ @pj @ph @pk @pl @pv @ps @pc @pn @pp @pq @py @pw @pg @po @pe @pr @pb @px @pz @pd C-A-/ _ @wsp @wsn @sft @sft)

        ;; f/j + shift: swap panes (h/j/k/l), new/rename/close workspace (n/w/d),
        ;; rename tab (t) / pane (p), new/open/remove worktree (g/o/b), reload (r),
        ;; settings (s), close tab (x), / -> ctrl+alt+shift+/ (? full list).
        (deflayer herdr-shift
          _ @sj @sh @sk @sl _ @ss _ @sn @sp _ _ @sw @sg @so _ @sr @sb @sx _ @sd C-A-S-/ @st _ _ _ _)
      '';
    };
  };
}
