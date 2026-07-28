{ pkgs, ... }:
{
  # steam-hardware tags /dev/uinput `uaccess`; with an ACL present, udev's
  # MODE="0660" GROUP="uinput" lands on the ACL mask instead of `group::`, so
  # kanata gets EACCES. `+` runs setfacl as root, outside the unit sandbox.
  systemd.services.kanata-default.serviceConfig.ExecStartPre =
    "+${pkgs.acl}/bin/setfacl -m g:uinput:rw /dev/uinput";

  # Home-row modifier for Herdr (home/programs/herdr), which has no hold-vs-tap
  # of its own. Tap f/j -> the letter; hold f/j (+ optional shift) -> a layer
  # driving Herdr's bindings. Both keys enter one layer, so hold with the hand
  # opposite the action key. Applies to every keyboard, system-wide.
  services.kanata = {
    enable = true;
    keyboards.default = {
      extraDefCfg = ''
        process-unmapped-keys yes
        concurrent-tap-hold yes
      '';

      config = ''
        (defalias
          ;; Hold action for f/j. Shift pressed first was already resolved in
          ;; base and is a real shift in the output, which would corrupt the
          ;; chord's modifiers; release it and enter herdr-shift directly.
          ;; Shift pressed after f/j is captured by @sft instead.
          hrd (fork
                (layer-while-held herdr)
                (multi (release-key lsft) (release-key rsft) (layer-while-held herdr-shift))
                (lsft rsft))

          ;; 200 200 = (tap-timeout, hold-timeout) ms.
          hrf (tap-hold-release 200 200 f @hrd)
          hrj (tap-hold-release 200 200 j @hrd)

          ;; Ctrl+b survives terminals; ctrl+alt would leak to the shell as Meta.
          ph (macro C-b h)  pj (macro C-b j)  pk (macro C-b k)  pl (macro C-b l)
          pv (macro C-b v)  ps (macro C-b s)  pc (macro C-b c)  pn (macro C-b n)
          pp (macro C-b p)  pq (macro C-b q)  py (macro C-b y)  pw (macro C-b w)
          pg (macro C-b g)  po (macro C-b o)  pe (macro C-b e)  pr (macro C-b r)
          pb (macro C-b b)  px (macro C-b x)  pz (macro C-b z)  pd (macro C-b d)

          ;; Shift-family: direct chords, not `C-b S-<key>` — a shift press
          ;; between prefix and letter drops Herdr out of prefix mode. See
          ;; home/programs/herdr.
          sh C-A-h  sj C-A-j  sk C-A-k  sl C-A-l
          sn C-A-n  sw C-A-w  st C-A-t  sp C-A-p
          sd C-A-d  sg C-A-g  sr C-A-r  ss C-A-s
          sx C-A-x  so C-A-o  sb C-A-b

          ;; Cycle spaces.
          wsp (macro C-b lbrc)  wsn (macro C-b rbrc)

          ;; Shift pressed while already in the herdr layer.
          sft (layer-while-held herdr-shift))

        ;; lsft/rsft are listed so the herdr layer can capture shift.
        (defsrc
          f j h k l v s c n p q y w g o e r b x z d / t lbrc rbrc lsft rsft)

        (deflayer base
          @hrf @hrj _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _)

        ;; f/j held. / -> ctrl+alt+/ (Hyprland cheatsheet bind).
        (deflayer herdr
          _ @pj @ph @pk @pl @pv @ps @pc @pn @pp @pq @py @pw @pg @po @pe @pr @pb @px @pz @pd C-A-/ _ @wsp @wsn @sft @sft)

        ;; f/j + shift: swap panes (h/j/k/l), new/rename/close workspace (n/w/d),
        ;; rename tab (t) / pane (p), new/open/remove worktree (g/o/b), reload (r),
        ;; settings (s), close tab (x), / -> the cheatsheet.
        (deflayer herdr-shift
          _ @sj @sh @sk @sl _ @ss _ @sn @sp _ _ @sw @sg @so _ @sr @sb @sx _ @sd C-A-S-/ @st _ _ _ _)
      '';
    };
  };
}
