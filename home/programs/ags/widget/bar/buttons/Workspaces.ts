import PanelButton from "../PanelButton";
import { sh } from "lib/utils";

const hyprland = await Service.import("hyprland");

const dispatch = (arg: string | number) => {
  hyprland.messageAsync(`dispatch workspace ${arg}`);
};

export default (monitor = 0) => {
  const activeId = hyprland.active.workspace.bind("id");

  return Widget.EventBox({
    onScrollUp: () => dispatch("+1"),
    onScrollDown: () => dispatch("-1"),
    class_name: "workspaces",
    child: Widget.Box({
      children: Array.from({ length: 9 }, (_, ws) => ws + 1).map((ws) =>
        PanelButton({
          onClicked: () => dispatch(ws),
          attribute: ws,
          child: Widget.Label({
            label: `${ws}`,
            class_name: activeId.as((i) => `${i === ws ? "active" : ""}`),
          }),
        }),
      ),

      // remove this setup hook if you want fixed number of buttons
      setup: (self) =>
        self.hook(hyprland, () =>
          self.children.forEach((btn) => {
            btn.visible = hyprland.workspaces.some(
              (_ws) => _ws.monitorID === monitor && _ws.id === btn.attribute,
            );
          }),
        ),
    }),
  });
};
