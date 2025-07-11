/// <reference path="./gio-2.0.d.ts" />
/// <reference path="./gobject-2.0.d.ts" />
/// <reference path="./glib-2.0.d.ts" />
/// <reference path="./gmodule-2.0.d.ts" />
/// <reference path="./gdkpixbuf-2.0.d.ts" />

/**
 * Type Definitions for Gjs (https://gjs.guide/)
 *
 * These type definitions are automatically generated, do not edit them by hand.
 * If you found a bug fix it in `ts-for-gir` or create a bug report on https://github.com/gjsify/ts-for-gir
 *
 * The based EJS template file is used for the generated .d.ts file of each GIR module like Gtk-4.0, GObject-2.0, ...
 */

declare module 'gi://AstalTray?version=0.1' {
    // Module dependencies
    import type Gio from 'gi://Gio?version=2.0';
    import type GObject from 'gi://GObject?version=2.0';
    import type GLib from 'gi://GLib?version=2.0';
    import type GModule from 'gi://GModule?version=2.0';
    import type GdkPixbuf from 'gi://GdkPixbuf?version=2.0';

    export namespace AstalTray {
        /**
         * AstalTray-0.1
         */

        export namespace Category {
            export const $gtype: GObject.GType<Category>;
        }

        enum Category {
            APPLICATION,
            COMMUNICATIONS,
            SYSTEM,
            HARDWARE,
        }

        export namespace Status {
            export const $gtype: GObject.GType<Status>;
        }

        enum Status {
            PASSIVE,
            ACTIVE,
            NEEDS_ATTENTION,
        }
        const MAJOR_VERSION: number;
        const MINOR_VERSION: number;
        const MICRO_VERSION: number;
        const VERSION: string;
        function category_to_nick(): string;
        function category_from_string(value: string): Category;
        function status_to_nick(): string;
        function status_from_string(value: string): Status;
        /**
         * Get the singleton instance of [class`AstalTray`.Tray]
         */
        function get_default(): Tray;
        namespace Tray {
            // Signal signatures
            interface SignalSignatures extends GObject.Object.SignalSignatures {
                'item-added': (arg0: string) => void;
                'item-removed': (arg0: string) => void;
                'notify::items': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends GObject.Object.ConstructorProps {
                items: TrayItem[];
            }
        }

        class Tray extends GObject.Object {
            static $gtype: GObject.GType<Tray>;

            // Properties

            /**
             * List of currently registered tray items
             */
            get items(): TrayItem[];

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Tray.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Tray.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Tray;

            // Signals

            connect<K extends keyof Tray.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Tray.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Tray.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Tray.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Tray.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Tray.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Static methods

            /**
             * Get the singleton instance of [class`AstalTray`.Tray]
             */
            static get_default(): Tray;

            // Methods

            /**
             * gets the TrayItem with the given item-id.
             * @param item_id
             */
            get_item(item_id: string): TrayItem;
            get_items(): TrayItem[];
        }

        namespace TrayItem {
            // Signal signatures
            interface SignalSignatures extends GObject.Object.SignalSignatures {
                changed: () => void;
                ready: () => void;
                'notify::title': (pspec: GObject.ParamSpec) => void;
                'notify::category': (pspec: GObject.ParamSpec) => void;
                'notify::status': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::id': (pspec: GObject.ParamSpec) => void;
                'notify::is-menu': (pspec: GObject.ParamSpec) => void;
                'notify::icon-theme-path': (pspec: GObject.ParamSpec) => void;
                'notify::icon-name': (pspec: GObject.ParamSpec) => void;
                'notify::icon-pixbuf': (pspec: GObject.ParamSpec) => void;
                'notify::gicon': (pspec: GObject.ParamSpec) => void;
                'notify::item-id': (pspec: GObject.ParamSpec) => void;
                'notify::menu-path': (pspec: GObject.ParamSpec) => void;
                'notify::menu-model': (pspec: GObject.ParamSpec) => void;
                'notify::action-group': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends GObject.Object.ConstructorProps {
                title: string;
                category: Category;
                status: Status;
                tooltip: Tooltip;
                tooltip_markup: string;
                tooltipMarkup: string;
                tooltip_text: string;
                tooltipText: string;
                id: string;
                is_menu: boolean;
                isMenu: boolean;
                icon_theme_path: string;
                iconThemePath: string;
                icon_name: string;
                iconName: string;
                icon_pixbuf: GdkPixbuf.Pixbuf;
                iconPixbuf: GdkPixbuf.Pixbuf;
                gicon: Gio.Icon;
                item_id: string;
                itemId: string;
                menu_path: never;
                menuPath: never;
                menu_model: Gio.MenuModel;
                menuModel: Gio.MenuModel;
                action_group: Gio.ActionGroup;
                actionGroup: Gio.ActionGroup;
            }
        }

        class TrayItem extends GObject.Object {
            static $gtype: GObject.GType<TrayItem>;

            // Properties

            /**
             * The Title of the TrayItem
             */
            get title(): string;
            set title(val: string);
            /**
             * The category this item belongs to
             */
            get category(): Category;
            set category(val: Category);
            /**
             * The current status of this item
             */
            get status(): Status;
            set status(val: Status);
            /**
             * The tooltip of this item
             */
            get tooltip(): Tooltip;
            set tooltip(val: Tooltip);
            /**
             * A markup representation of the tooltip. This is basically equvivalent to `tooltip.title \n tooltip.description`
             */
            get tooltip_markup(): string;
            /**
             * A markup representation of the tooltip. This is basically equvivalent to `tooltip.title \n tooltip.description`
             */
            get tooltipMarkup(): string;
            /**
             * A text representation of the tooltip. This is basically equvivalent to `tooltip.title \n tooltip.description.`
             */
            get tooltip_text(): string;
            /**
             * A text representation of the tooltip. This is basically equvivalent to `tooltip.title \n tooltip.description.`
             */
            get tooltipText(): string;
            /**
             * the id of the item. This id is specified by the tray app.
             */
            get id(): string;
            set id(val: string);
            /**
             * If set, this only supports the menu, so showing the menu should be prefered over calling [method`AstalTray`.TrayItem.activate].
             */
            get is_menu(): boolean;
            set is_menu(val: boolean);
            /**
             * If set, this only supports the menu, so showing the menu should be prefered over calling [method`AstalTray`.TrayItem.activate].
             */
            get isMenu(): boolean;
            set isMenu(val: boolean);
            /**
             * The icon theme path, where to look for the [property`AstalTray`.TrayItem:icon-name]. It is recommended to use the [property@
             * AstalTray.TrayItem:gicon] property, which does the icon lookups for you.
             */
            get icon_theme_path(): string;
            set icon_theme_path(val: string);
            /**
             * The icon theme path, where to look for the [property`AstalTray`.TrayItem:icon-name]. It is recommended to use the [property@
             * AstalTray.TrayItem:gicon] property, which does the icon lookups for you.
             */
            get iconThemePath(): string;
            set iconThemePath(val: string);
            /**
             * The name of the icon. This should be looked up in the [property`AstalTray`.TrayItem:icon-theme-path] if set or in the currently used icon
             * theme otherwise. It is recommended to use the [property`AstalTray`.TrayItem:gicon] property, which does the icon lookups for you.
             */
            get icon_name(): string;
            /**
             * The name of the icon. This should be looked up in the [property`AstalTray`.TrayItem:icon-theme-path] if set or in the currently used icon
             * theme otherwise. It is recommended to use the [property`AstalTray`.TrayItem:gicon] property, which does the icon lookups for you.
             */
            get iconName(): string;
            /**
             * A pixbuf containing the icon. It is recommended to use the [property`AstalTray`.TrayItem:gicon] property, which does the icon lookups for
             * you.
             */
            get icon_pixbuf(): GdkPixbuf.Pixbuf;
            /**
             * A pixbuf containing the icon. It is recommended to use the [property`AstalTray`.TrayItem:gicon] property, which does the icon lookups for
             * you.
             */
            get iconPixbuf(): GdkPixbuf.Pixbuf;
            /**
             * Contains the items icon. This property is intended to be used with the gicon property of the Icon widget and the recommended way to display the
             * icon. This property unifies the [property`AstalTray`.TrayItem:icon-name], [property`AstalTray`.TrayItem:icon-theme-path] and [property
             * `AstalTray`.TrayItem:icon-pixbuf] properties.
             */
            get gicon(): Gio.Icon;
            set gicon(val: Gio.Icon);
            /**
             * The id of the item used to uniquely identify the TrayItems by this lib.
             */
            get item_id(): string;
            set item_id(val: string);
            /**
             * The id of the item used to uniquely identify the TrayItems by this lib.
             */
            get itemId(): string;
            set itemId(val: string);
            /**
             * The object path to the dbusmenu
             */
            get menu_path(): never;
            set menu_path(val: never);
            /**
             * The object path to the dbusmenu
             */
            get menuPath(): never;
            set menuPath(val: never);
            /**
             * The MenuModel describing the menu for this TrayItem to be used with a MenuButton or PopoverMenu. The actions for this menu are defined in
             * [property`AstalTray`.TrayItem:action-group].
             */
            get menu_model(): Gio.MenuModel;
            /**
             * The MenuModel describing the menu for this TrayItem to be used with a MenuButton or PopoverMenu. The actions for this menu are defined in
             * [property`AstalTray`.TrayItem:action-group].
             */
            get menuModel(): Gio.MenuModel;
            /**
             * The ActionGroup containing the actions for the menu. All actions have the `dbusmenu` prefix and are setup to work with the [property@
             * AstalTray.TrayItem:menu-model]. Make sure to insert this action group into a parent widget of the menu, eg the MenuButton for which the MenuModel for
             * this TrayItem is set.
             */
            get action_group(): Gio.ActionGroup;
            /**
             * The ActionGroup containing the actions for the menu. All actions have the `dbusmenu` prefix and are setup to work with the [property@
             * AstalTray.TrayItem:menu-model]. Make sure to insert this action group into a parent widget of the menu, eg the MenuButton for which the MenuModel for
             * this TrayItem is set.
             */
            get actionGroup(): Gio.ActionGroup;

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: TrayItem.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<TrayItem.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            // Signals

            connect<K extends keyof TrayItem.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, TrayItem.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof TrayItem.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, TrayItem.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof TrayItem.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<TrayItem.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            /**
             * tells the tray app that its menu is about to be opened, so it can update the menu if needed. You should call this method before openening the
             * menu.
             */
            about_to_show(): void;
            /**
             * Send an activate request to the tray app.
             * @param x
             * @param y
             */
            activate(x: number, y: number): void;
            /**
             * Send a secondary activate request to the tray app.
             * @param x
             * @param y
             */
            secondary_activate(x: number, y: number): void;
            /**
             * Send a scroll request to the tray app. valid values for the orientation are "horizontal" and "vertical".
             * @param delta
             * @param orientation
             */
            scroll(delta: number, orientation: string): void;
            to_json_string(): string;
            get_title(): string;
            get_category(): Category;
            get_status(): Status;
            get_tooltip(): Tooltip | null;
            get_tooltip_markup(): string;
            get_tooltip_text(): string;
            get_id(): string;
            get_is_menu(): boolean;
            get_icon_theme_path(): string;
            get_icon_name(): string;
            get_icon_pixbuf(): GdkPixbuf.Pixbuf;
            get_gicon(): Gio.Icon;
            get_item_id(): string;
            get_menu_path(): never;
            get_menu_model(): Gio.MenuModel | null;
            get_action_group(): Gio.ActionGroup | null;
        }

        type TrayClass = typeof Tray;
        abstract class TrayPrivate {
            static $gtype: GObject.GType<TrayPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type TrayItemClass = typeof TrayItem;
        abstract class TrayItemPrivate {
            static $gtype: GObject.GType<TrayItemPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        class Pixmap {
            static $gtype: GObject.GType<Pixmap>;

            // Fields

            width: number;
            height: number;
            bytes: Uint8Array;
            bytes_length1: number;

            // Constructors

            constructor(
                properties?: Partial<{
                    width: number;
                    height: number;
                    bytes: Uint8Array;
                    bytes_length1: number;
                }>,
            );
            _init(...args: any[]): void;
        }

        class Tooltip {
            static $gtype: GObject.GType<Tooltip>;

            // Fields

            icon_name: string;
            icon: Pixmap[];
            icon_length1: number;
            title: string;
            description: string;

            // Constructors

            constructor(
                properties?: Partial<{
                    icon_name: string;
                    icon: Pixmap[];
                    icon_length1: number;
                    title: string;
                    description: string;
                }>,
            );
            _init(...args: any[]): void;
        }

        /**
         * Name of the imported GIR library
         * `see` https://gitlab.gnome.org/GNOME/gjs/-/blob/master/gi/ns.cpp#L188
         */
        const __name__: string;
        /**
         * Version of the imported GIR library
         * `see` https://gitlab.gnome.org/GNOME/gjs/-/blob/master/gi/ns.cpp#L189
         */
        const __version__: string;
    }

    export default AstalTray;
}

declare module 'gi://AstalTray' {
    import AstalTray01 from 'gi://AstalTray?version=0.1';
    export default AstalTray01;
}
// END
