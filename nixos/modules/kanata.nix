{ pkgs, ... }:
{
  # steam-hardware tags /dev/uinput `uaccess`; with an ACL present, udev's
  # MODE="0660" GROUP="uinput" lands on the ACL mask instead of `group::`, so
  # kanata gets EACCES. `+` runs setfacl as root, outside the unit sandbox.
  systemd.services.kanata-default.serviceConfig.ExecStartPre =
    "+${pkgs.acl}/bin/setfacl -m g:uinput:rw /dev/uinput";

  # Home-row modifier for Herdr (home/programs/herdr), which has no hold-vs-tap
  # of its own: tap f/j -> the letter, hold f/j -> layer emitting Herdr's
  # `ctrl+b <key>` prefix. Both keys enter one layer, so hold with the hand
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
          ;; 200 200 = (tap-timeout, hold-timeout) ms.
          hrf (tap-hold-release 200 200 f (layer-while-held herdr))
          hrj (tap-hold-release 200 200 j (layer-while-held herdr))

          ;; Ctrl+b survives terminals; ctrl+alt would leak to the shell as Meta.
          ph (macro C-b h)  pj (macro C-b j)  pk (macro C-b k)  pl (macro C-b l)
          pv (macro C-b v)  ps (macro C-b s)  pc (macro C-b c)  pn (macro C-b n)
          pp (macro C-b p)  pq (macro C-b q)  py (macro C-b y)  pw (macro C-b w)
          pg (macro C-b g)  po (macro C-b o)  pe (macro C-b e)  pr (macro C-b r)
          pb (macro C-b b)  px (macro C-b x)  pz (macro C-b z)  pd (macro C-b d)

          ;; kanata emits the shift itself; a raw OS shift would leak.
          sh (macro C-b S-h)  sj (macro C-b S-j)  sk (macro C-b S-k)  sl (macro C-b S-l)
          sn (macro C-b S-n)  sw (macro C-b S-w)  st (macro C-b S-t)  sp (macro C-b S-p)
          sd (macro C-b S-d)  sg (macro C-b S-g)  sr (macro C-b S-r)  ss (macro C-b S-s)
          sx (macro C-b S-x)  so (macro C-b S-o)  sb (macro C-b S-b)

          ;; Cycle spaces.
          wsp (macro C-b lbrc)  wsn (macro C-b rbrc)

          ;; Press f/j BEFORE shift, else shift is a raw OS shift in base.
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
        ;; settings (s), close tab (x), / -> ctrl+alt+shift+/ (? full list).
        (deflayer herdr-shift
          _ @sj @sh @sk @sl _ @ss _ @sn @sp _ _ @sw @sg @so _ @sr @sb @sx _ @sd C-A-S-/ @st _ _ _ _)
      '';
    };
  };
}
