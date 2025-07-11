/// <reference path="./astalio-0.1.d.ts" />
/// <reference path="./glib-2.0.d.ts" />
/// <reference path="./gobject-2.0.d.ts" />
/// <reference path="./gio-2.0.d.ts" />
/// <reference path="./gmodule-2.0.d.ts" />
/// <reference path="./gdk-3.0.d.ts" />
/// <reference path="./cairo-1.0.d.ts" />
/// <reference path="./cairo.d.ts" />
/// <reference path="./pango-1.0.d.ts" />
/// <reference path="./harfbuzz-0.0.d.ts" />
/// <reference path="./freetype2-2.0.d.ts" />
/// <reference path="./gdkpixbuf-2.0.d.ts" />
/// <reference path="./gtk-3.0.d.ts" />
/// <reference path="./xlib-2.0.d.ts" />
/// <reference path="./atk-1.0.d.ts" />

/**
 * Type Definitions for Gjs (https://gjs.guide/)
 *
 * These type definitions are automatically generated, do not edit them by hand.
 * If you found a bug fix it in `ts-for-gir` or create a bug report on https://github.com/gjsify/ts-for-gir
 *
 * The based EJS template file is used for the generated .d.ts file of each GIR module like Gtk-4.0, GObject-2.0, ...
 */

declare module 'gi://Astal?version=3.0' {
    // Module dependencies
    import type AstalIO from 'gi://AstalIO?version=0.1';
    import type GLib from 'gi://GLib?version=2.0';
    import type GObject from 'gi://GObject?version=2.0';
    import type Gio from 'gi://Gio?version=2.0';
    import type GModule from 'gi://GModule?version=2.0';
    import type Gdk from 'gi://Gdk?version=3.0';
    import type cairo from 'cairo';
    import type Pango from 'gi://Pango?version=1.0';
    import type HarfBuzz from 'gi://HarfBuzz?version=0.0';
    import type freetype2 from 'gi://freetype2?version=2.0';
    import type GdkPixbuf from 'gi://GdkPixbuf?version=2.0';
    import type Gtk from 'gi://Gtk?version=3.0';
    import type xlib from 'gi://xlib?version=2.0';
    import type Atk from 'gi://Atk?version=1.0';

    export namespace Astal {
        /**
         * Astal-3.0
         */

        export namespace MouseButton {
            export const $gtype: GObject.GType<MouseButton>;
        }

        enum MouseButton {
            PRIMARY,
            MIDDLE,
            SECONDARY,
            BACK,
            FORWARD,
        }

        export namespace Exclusivity {
            export const $gtype: GObject.GType<Exclusivity>;
        }

        enum Exclusivity {
            NORMAL,
            /**
             * Request the compositor to allocate space for this window.
             */
            EXCLUSIVE,
            /**
             * Request the compositor to stack layers on top of each other.
             */
            IGNORE,
        }

        export namespace Layer {
            export const $gtype: GObject.GType<Layer>;
        }

        enum Layer {
            BACKGROUND,
            BOTTOM,
            TOP,
            OVERLAY,
        }

        export namespace Keymode {
            export const $gtype: GObject.GType<Keymode>;
        }

        enum Keymode {
            /**
             * Window should not receive keyboard events.
             */
            NONE,
            /**
             * Window should have exclusive focus if it is on the top or overlay layer.
             */
            EXCLUSIVE,
            /**
             * Focus and Unfocues the window as needed.
             */
            ON_DEMAND,
        }
        const MAJOR_VERSION: number;
        const MINOR_VERSION: number;
        const MICRO_VERSION: number;
        const VERSION: string;
        function widget_set_css(widget: Gtk.Widget, css: string): void;
        function widget_get_css(widget: Gtk.Widget): string;
        function widget_set_class_names(widget: Gtk.Widget, class_names: string[]): void;
        function widget_get_class_names(widget: Gtk.Widget): string[];
        function widget_toggle_class_name(widget: Gtk.Widget, class_name: string, condition: boolean): void;
        function widget_set_cursor(widget: Gtk.Widget, cursor: string): void;
        function widget_get_cursor(widget: Gtk.Widget): string;
        function widget_set_click_through(widget: Gtk.Widget, click_through: boolean): void;
        function widget_get_click_through(widget: Gtk.Widget): boolean;

        export namespace WindowAnchor {
            export const $gtype: GObject.GType<WindowAnchor>;
        }

        enum WindowAnchor {
            NONE,
            TOP,
            RIGHT,
            LEFT,
            BOTTOM,
        }
        namespace Box {
            // Signal signatures
            interface SignalSignatures extends Gtk.Box.SignalSignatures {
                'notify::vertical': (pspec: GObject.ParamSpec) => void;
                'notify::children': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::baseline-position': (pspec: GObject.ParamSpec) => void;
                'notify::homogeneous': (pspec: GObject.ParamSpec) => void;
                'notify::spacing': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Box.ConstructorProps {
                vertical: boolean;
                children: Gtk.Widget[];
                child: Gtk.Widget;
            }
        }

        class Box extends Gtk.Box {
            static $gtype: GObject.GType<Box>;

            // Properties

            /**
             * Corresponds to [property`Gtk`.Orientable :orientation].
             */
            get vertical(): boolean;
            set vertical(val: boolean);
            get children(): Gtk.Widget[];
            set children(val: Gtk.Widget[]);
            get child(): Gtk.Widget;
            set child(val: Gtk.Widget);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Box.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Box.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](vertical: boolean, children: Gtk.Widget[]): Box;
            // Conflicted with Gtk.Box.new

            static ['new'](...args: never[]): any;

            // Signals

            connect<K extends keyof Box.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Box.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Box.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Box.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Box.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Box.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_vertical(): boolean;
            set_vertical(value: boolean): void;
            get_children(): Gtk.Widget[];
            set_children(value: Gtk.Widget[]): void;
            get_child(): Gtk.Widget;
            set_child(value: Gtk.Widget): void;
        }

        namespace Button {
            // Signal signatures
            interface SignalSignatures extends Gtk.Button.SignalSignatures {
                hover: (arg0: HoverEvent) => void;
                'hover-lost': (arg0: HoverEvent) => void;
                click: (arg0: ClickEvent) => void;
                'click-release': (arg0: ClickEvent) => void;
                scroll: (arg0: ScrollEvent) => void;
                'notify::always-show-image': (pspec: GObject.ParamSpec) => void;
                'notify::image': (pspec: GObject.ParamSpec) => void;
                'notify::image-position': (pspec: GObject.ParamSpec) => void;
                'notify::label': (pspec: GObject.ParamSpec) => void;
                'notify::relief': (pspec: GObject.ParamSpec) => void;
                'notify::use-stock': (pspec: GObject.ParamSpec) => void;
                'notify::use-underline': (pspec: GObject.ParamSpec) => void;
                'notify::xalign': (pspec: GObject.ParamSpec) => void;
                'notify::yalign': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Button.ConstructorProps {}
        }

        /**
         * This button has no extra functionality on top if its base [class`Gtk`.Button] class.
         * The purpose of this Button subclass is to have a destructable struct as the argument in GJS event handlers.
         */
        class Button extends Gtk.Button {
            static $gtype: GObject.GType<Button>;

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Button.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Button.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Button;

            // Signals

            connect<K extends keyof Button.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Button.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Button.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Button.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Button.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Button.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;
        }

        namespace CenterBox {
            // Signal signatures
            interface SignalSignatures extends Gtk.Box.SignalSignatures {
                'notify::vertical': (pspec: GObject.ParamSpec) => void;
                'notify::start-widget': (pspec: GObject.ParamSpec) => void;
                'notify::end-widget': (pspec: GObject.ParamSpec) => void;
                'notify::center-widget': (pspec: GObject.ParamSpec) => void;
                'notify::baseline-position': (pspec: GObject.ParamSpec) => void;
                'notify::homogeneous': (pspec: GObject.ParamSpec) => void;
                'notify::spacing': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Box.ConstructorProps, Gtk.Buildable.ConstructorProps {
                vertical: boolean;
                start_widget: Gtk.Widget;
                startWidget: Gtk.Widget;
                end_widget: Gtk.Widget;
                endWidget: Gtk.Widget;
                center_widget: Gtk.Widget;
                centerWidget: Gtk.Widget;
            }
        }

        class CenterBox extends Gtk.Box implements Gtk.Buildable {
            static $gtype: GObject.GType<CenterBox>;

            // Properties

            /**
             * Corresponds to [property`Gtk`.Orientable :orientation].
             */
            get vertical(): boolean;
            set vertical(val: boolean);
            get start_widget(): Gtk.Widget;
            set start_widget(val: Gtk.Widget);
            get startWidget(): Gtk.Widget;
            set startWidget(val: Gtk.Widget);
            get end_widget(): Gtk.Widget;
            set end_widget(val: Gtk.Widget);
            get endWidget(): Gtk.Widget;
            set endWidget(val: Gtk.Widget);
            get center_widget(): Gtk.Widget;
            set center_widget(val: Gtk.Widget);
            get centerWidget(): Gtk.Widget;
            set centerWidget(val: Gtk.Widget);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: CenterBox.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<CenterBox.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): CenterBox;

            // Signals

            connect<K extends keyof CenterBox.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, CenterBox.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof CenterBox.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, CenterBox.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof CenterBox.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<CenterBox.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_vertical(): boolean;
            set_vertical(value: boolean): void;
            get_start_widget(): Gtk.Widget;
            set_start_widget(value: Gtk.Widget): void;
            get_end_widget(): Gtk.Widget;
            set_end_widget(value: Gtk.Widget): void;
            get_center_widget(): Gtk.Widget;
            // Conflicted with Gtk.Box.get_center_widget
            get_center_widget(...args: never[]): any;
            set_center_widget(value: Gtk.Widget): void;
            // Conflicted with Gtk.Box.set_center_widget
            set_center_widget(...args: never[]): any;

            // Inherited methods
            /**
             * Creates a binding between `source_property` on `source` and `target_property`
             * on `target`.
             *
             * Whenever the `source_property` is changed the `target_property` is
             * updated using the same value. For instance:
             *
             *
             * ```c
             *   g_object_bind_property (action, "active", widget, "sensitive", 0);
             * ```
             *
             *
             * Will result in the "sensitive" property of the widget #GObject instance to be
             * updated with the same value of the "active" property of the action #GObject
             * instance.
             *
             * If `flags` contains %G_BINDING_BIDIRECTIONAL then the binding will be mutual:
             * if `target_property` on `target` changes then the `source_property` on `source`
             * will be updated as well.
             *
             * The binding will automatically be removed when either the `source` or the
             * `target` instances are finalized. To remove the binding without affecting the
             * `source` and the `target` you can just call g_object_unref() on the returned
             * #GBinding instance.
             *
             * Removing the binding by calling g_object_unref() on it must only be done if
             * the binding, `source` and `target` are only used from a single thread and it
             * is clear that both `source` and `target` outlive the binding. Especially it
             * is not safe to rely on this if the binding, `source` or `target` can be
             * finalized from different threads. Keep another reference to the binding and
             * use g_binding_unbind() instead to be on the safe side.
             *
             * A #GObject can have multiple bindings.
             * @param source_property the property on @source to bind
             * @param target the target #GObject
             * @param target_property the property on @target to bind
             * @param flags flags to pass to #GBinding
             * @returns the #GBinding instance representing the     binding between the two #GObject instances. The binding is released     whenever the #GBinding reference count reaches zero.
             */
            bind_property(
                source_property: string,
                target: GObject.Object,
                target_property: string,
                flags: GObject.BindingFlags | null,
            ): GObject.Binding;
            /**
             * Complete version of g_object_bind_property().
             *
             * Creates a binding between `source_property` on `source` and `target_property`
             * on `target,` allowing you to set the transformation functions to be used by
             * the binding.
             *
             * If `flags` contains %G_BINDING_BIDIRECTIONAL then the binding will be mutual:
             * if `target_property` on `target` changes then the `source_property` on `source`
             * will be updated as well. The `transform_from` function is only used in case
             * of bidirectional bindings, otherwise it will be ignored
             *
             * The binding will automatically be removed when either the `source` or the
             * `target` instances are finalized. This will release the reference that is
             * being held on the #GBinding instance; if you want to hold on to the
             * #GBinding instance, you will need to hold a reference to it.
             *
             * To remove the binding, call g_binding_unbind().
             *
             * A #GObject can have multiple bindings.
             *
             * The same `user_data` parameter will be used for both `transform_to`
             * and `transform_from` transformation functions; the `notify` function will
             * be called once, when the binding is removed. If you need different data
             * for each transformation function, please use
             * g_object_bind_property_with_closures() instead.
             * @param source_property the property on @source to bind
             * @param target the target #GObject
             * @param target_property the property on @target to bind
             * @param flags flags to pass to #GBinding
             * @param transform_to the transformation function     from the @source to the @target, or %NULL to use the default
             * @param transform_from the transformation function     from the @target to the @source, or %NULL to use the default
             * @param notify a function to call when disposing the binding, to free     resources used by the transformation functions, or %NULL if not required
             * @returns the #GBinding instance representing the     binding between the two #GObject instances. The binding is released     whenever the #GBinding reference count reaches zero.
             */
            bind_property_full(
                source_property: string,
                target: GObject.Object,
                target_property: string,
                flags: GObject.BindingFlags | null,
                transform_to?: GObject.BindingTransformFunc | null,
                transform_from?: GObject.BindingTransformFunc | null,
                notify?: GLib.DestroyNotify | null,
            ): GObject.Binding;
            // Conflicted with GObject.Object.bind_property_full
            bind_property_full(...args: never[]): any;
            /**
             * This function is intended for #GObject implementations to re-enforce
             * a [floating][floating-ref] object reference. Doing this is seldom
             * required: all #GInitiallyUnowneds are created with a floating reference
             * which usually just needs to be sunken by calling g_object_ref_sink().
             */
            force_floating(): void;
            /**
             * Increases the freeze count on `object`. If the freeze count is
             * non-zero, the emission of "notify" signals on `object` is
             * stopped. The signals are queued until the freeze count is decreased
             * to zero. Duplicate notifications are squashed so that at most one
             * #GObject::notify signal is emitted for each property modified while the
             * object is frozen.
             *
             * This is necessary for accessors that modify multiple properties to prevent
             * premature notification while the object is still being modified.
             */
            freeze_notify(): void;
            /**
             * Gets a named field from the objects table of associations (see g_object_set_data()).
             * @param key name of the key for that association
             * @returns the data if found,          or %NULL if no such data exists.
             */
            get_data(key: string): any | null;
            /**
             * Gets a property of an object.
             *
             * The value can be:
             * - an empty GObject.Value initialized by G_VALUE_INIT, which will be automatically initialized with the expected type of the property (since GLib 2.60)
             * - a GObject.Value initialized with the expected type of the property
             * - a GObject.Value initialized with a type to which the expected type of the property can be transformed
             *
             * In general, a copy is made of the property contents and the caller is responsible for freeing the memory by calling GObject.Value.unset.
             *
             * Note that GObject.Object.get_property is really intended for language bindings, GObject.Object.get is much more convenient for C programming.
             * @param property_name The name of the property to get
             * @param value Return location for the property value. Can be an empty GObject.Value initialized by G_VALUE_INIT (auto-initialized with expected type since GLib 2.60), a GObject.Value initialized with the expected property type, or a GObject.Value initialized with a transformable type
             */
            get_property(property_name: string, value: GObject.Value | any): any;
            /**
             * This function gets back user data pointers stored via
             * g_object_set_qdata().
             * @param quark A #GQuark, naming the user data pointer
             * @returns The user data pointer set, or %NULL
             */
            get_qdata(quark: GLib.Quark): any | null;
            /**
             * Gets `n_properties` properties for an `object`.
             * Obtained properties will be set to `values`. All properties must be valid.
             * Warnings will be emitted and undefined behaviour may result if invalid
             * properties are passed in.
             * @param names the names of each property to get
             * @param values the values of each property to get
             */
            getv(names: string[], values: (GObject.Value | any)[]): void;
            /**
             * Checks whether `object` has a [floating][floating-ref] reference.
             * @returns %TRUE if @object has a floating reference
             */
            is_floating(): boolean;
            /**
             * Emits a "notify" signal for the property `property_name` on `object`.
             *
             * When possible, eg. when signaling a property change from within the class
             * that registered the property, you should use g_object_notify_by_pspec()
             * instead.
             *
             * Note that emission of the notify signal may be blocked with
             * g_object_freeze_notify(). In this case, the signal emissions are queued
             * and will be emitted (in reverse order) when g_object_thaw_notify() is
             * called.
             * @param property_name the name of a property installed on the class of @object.
             */
            notify(property_name: string): void;
            /**
             * Emits a "notify" signal for the property specified by `pspec` on `object`.
             *
             * This function omits the property name lookup, hence it is faster than
             * g_object_notify().
             *
             * One way to avoid using g_object_notify() from within the
             * class that registered the properties, and using g_object_notify_by_pspec()
             * instead, is to store the GParamSpec used with
             * g_object_class_install_property() inside a static array, e.g.:
             *
             *
             * ```c
             *   typedef enum
             *   {
             *     PROP_FOO = 1,
             *     PROP_LAST
             *   } MyObjectProperty;
             *
             *   static GParamSpec *properties[PROP_LAST];
             *
             *   static void
             *   my_object_class_init (MyObjectClass *klass)
             *   {
             *     properties[PROP_FOO] = g_param_spec_int ("foo", NULL, NULL,
             *                                              0, 100,
             *                                              50,
             *                                              G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
             *     g_object_class_install_property (gobject_class,
             *                                      PROP_FOO,
             *                                      properties[PROP_FOO]);
             *   }
             * ```
             *
             *
             * and then notify a change on the "foo" property with:
             *
             *
             * ```c
             *   g_object_notify_by_pspec (self, properties[PROP_FOO]);
             * ```
             *
             * @param pspec the #GParamSpec of a property installed on the class of @object.
             */
            notify_by_pspec(pspec: GObject.ParamSpec): void;
            /**
             * Increases the reference count of `object`.
             *
             * Since GLib 2.56, if `GLIB_VERSION_MAX_ALLOWED` is 2.56 or greater, the type
             * of `object` will be propagated to the return type (using the GCC typeof()
             * extension), so any casting the caller needs to do on the return type must be
             * explicit.
             * @returns the same @object
             */
            ref(): GObject.Object;
            /**
             * Increase the reference count of `object,` and possibly remove the
             * [floating][floating-ref] reference, if `object` has a floating reference.
             *
             * In other words, if the object is floating, then this call "assumes
             * ownership" of the floating reference, converting it to a normal
             * reference by clearing the floating flag while leaving the reference
             * count unchanged.  If the object is not floating, then this call
             * adds a new normal reference increasing the reference count by one.
             *
             * Since GLib 2.56, the type of `object` will be propagated to the return type
             * under the same conditions as for g_object_ref().
             * @returns @object
             */
            ref_sink(): GObject.Object;
            /**
             * Releases all references to other objects. This can be used to break
             * reference cycles.
             *
             * This function should only be called from object system implementations.
             */
            run_dispose(): void;
            /**
             * Each object carries around a table of associations from
             * strings to pointers.  This function lets you set an association.
             *
             * If the object already had an association with that name,
             * the old association will be destroyed.
             *
             * Internally, the `key` is converted to a #GQuark using g_quark_from_string().
             * This means a copy of `key` is kept permanently (even after `object` has been
             * finalized) — so it is recommended to only use a small, bounded set of values
             * for `key` in your program, to avoid the #GQuark storage growing unbounded.
             * @param key name of the key
             * @param data data to associate with that key
             */
            set_data(key: string, data?: any | null): void;
            /**
             * Sets a property on an object.
             * @param property_name The name of the property to set
             * @param value The value to set the property to
             */
            set_property(property_name: string, value: GObject.Value | any): void;
            /**
             * Remove a specified datum from the object's data associations,
             * without invoking the association's destroy handler.
             * @param key name of the key
             * @returns the data if found, or %NULL          if no such data exists.
             */
            steal_data(key: string): any | null;
            /**
             * This function gets back user data pointers stored via
             * g_object_set_qdata() and removes the `data` from object
             * without invoking its destroy() function (if any was
             * set).
             * Usually, calling this function is only required to update
             * user data pointers with a destroy notifier, for example:
             *
             * ```c
             * void
             * object_add_to_user_list (GObject     *object,
             *                          const gchar *new_string)
             * {
             *   // the quark, naming the object data
             *   GQuark quark_string_list = g_quark_from_static_string ("my-string-list");
             *   // retrieve the old string list
             *   GList *list = g_object_steal_qdata (object, quark_string_list);
             *
             *   // prepend new string
             *   list = g_list_prepend (list, g_strdup (new_string));
             *   // this changed 'list', so we need to set it again
             *   g_object_set_qdata_full (object, quark_string_list, list, free_string_list);
             * }
             * static void
             * free_string_list (gpointer data)
             * {
             *   GList *node, *list = data;
             *
             *   for (node = list; node; node = node->next)
             *     g_free (node->data);
             *   g_list_free (list);
             * }
             * ```
             *
             * Using g_object_get_qdata() in the above example, instead of
             * g_object_steal_qdata() would have left the destroy function set,
             * and thus the partial string list would have been freed upon
             * g_object_set_qdata_full().
             * @param quark A #GQuark, naming the user data pointer
             * @returns The user data pointer set, or %NULL
             */
            steal_qdata(quark: GLib.Quark): any | null;
            /**
             * Reverts the effect of a previous call to
             * g_object_freeze_notify(). The freeze count is decreased on `object`
             * and when it reaches zero, queued "notify" signals are emitted.
             *
             * Duplicate notifications for each property are squashed so that at most one
             * #GObject::notify signal is emitted for each property, in the reverse order
             * in which they have been queued.
             *
             * It is an error to call this function when the freeze count is zero.
             */
            thaw_notify(): void;
            /**
             * Decreases the reference count of `object`. When its reference count
             * drops to 0, the object is finalized (i.e. its memory is freed).
             *
             * If the pointer to the #GObject may be reused in future (for example, if it is
             * an instance variable of another object), it is recommended to clear the
             * pointer to %NULL rather than retain a dangling pointer to a potentially
             * invalid #GObject instance. Use g_clear_object() for this.
             */
            unref(): void;
            /**
             * This function essentially limits the life time of the `closure` to
             * the life time of the object. That is, when the object is finalized,
             * the `closure` is invalidated by calling g_closure_invalidate() on
             * it, in order to prevent invocations of the closure with a finalized
             * (nonexisting) object. Also, g_object_ref() and g_object_unref() are
             * added as marshal guards to the `closure,` to ensure that an extra
             * reference count is held on `object` during invocation of the
             * `closure`.  Usually, this function will be called on closures that
             * use this `object` as closure data.
             * @param closure #GClosure to watch
             */
            watch_closure(closure: GObject.Closure): void;
            /**
             * the `constructed` function is called by g_object_new() as the
             *  final step of the object creation process.  At the point of the call, all
             *  construction properties have been set on the object.  The purpose of this
             *  call is to allow for object initialisation steps that can only be performed
             *  after construction properties have been set.  `constructed` implementors
             *  should chain up to the `constructed` call of their parent class to allow it
             *  to complete its initialisation.
             */
            vfunc_constructed(): void;
            /**
             * emits property change notification for a bunch
             *  of properties. Overriding `dispatch_properties_changed` should be rarely
             *  needed.
             * @param n_pspecs
             * @param pspecs
             */
            vfunc_dispatch_properties_changed(n_pspecs: number, pspecs: GObject.ParamSpec): void;
            /**
             * the `dispose` function is supposed to drop all references to other
             *  objects, but keep the instance otherwise intact, so that client method
             *  invocations still work. It may be run multiple times (due to reference
             *  loops). Before returning, `dispose` should chain up to the `dispose` method
             *  of the parent class.
             */
            vfunc_dispose(): void;
            /**
             * instance finalization function, should finish the finalization of
             *  the instance begun in `dispose` and chain up to the `finalize` method of the
             *  parent class.
             */
            vfunc_finalize(): void;
            /**
             * the generic getter for all properties of this type. Should be
             *  overridden for every type with properties.
             * @param property_id
             * @param value
             * @param pspec
             */
            vfunc_get_property(property_id: number, value: GObject.Value | any, pspec: GObject.ParamSpec): void;
            /**
             * Emits a "notify" signal for the property `property_name` on `object`.
             *
             * When possible, eg. when signaling a property change from within the class
             * that registered the property, you should use g_object_notify_by_pspec()
             * instead.
             *
             * Note that emission of the notify signal may be blocked with
             * g_object_freeze_notify(). In this case, the signal emissions are queued
             * and will be emitted (in reverse order) when g_object_thaw_notify() is
             * called.
             * @param pspec
             */
            vfunc_notify(pspec: GObject.ParamSpec): void;
            /**
             * the generic setter for all properties of this type. Should be
             *  overridden for every type with properties. If implementations of
             *  `set_property` don't emit property change notification explicitly, this will
             *  be done implicitly by the type system. However, if the notify signal is
             *  emitted explicitly, the type system will not emit it a second time.
             * @param property_id
             * @param value
             * @param pspec
             */
            vfunc_set_property(property_id: number, value: GObject.Value | any, pspec: GObject.ParamSpec): void;
            /**
             * Disconnects a handler from an instance so it will not be called during any future or currently ongoing emissions of the signal it has been connected to.
             * @param id Handler ID of the handler to be disconnected
             */
            disconnect(id: number): void;
            /**
             * Sets multiple properties of an object at once. The properties argument should be a dictionary mapping property names to values.
             * @param properties Object containing the properties to set
             */
            set(properties: { [key: string]: any }): void;
            /**
             * Blocks a handler of an instance so it will not be called during any signal emissions
             * @param id Handler ID of the handler to be blocked
             */
            block_signal_handler(id: number): void;
            /**
             * Unblocks a handler so it will be called again during any signal emissions
             * @param id Handler ID of the handler to be unblocked
             */
            unblock_signal_handler(id: number): void;
            /**
             * Stops a signal's emission by the given signal name. This will prevent the default handler and any subsequent signal handlers from being invoked.
             * @param detailedName Name of the signal to stop emission of
             */
            stop_emission_by_name(detailedName: string): void;
        }

        namespace CircularProgress {
            // Signal signatures
            interface SignalSignatures extends Gtk.Bin.SignalSignatures {
                'notify::start-at': (pspec: GObject.ParamSpec) => void;
                'notify::end-at': (pspec: GObject.ParamSpec) => void;
                'notify::value': (pspec: GObject.ParamSpec) => void;
                'notify::inverted': (pspec: GObject.ParamSpec) => void;
                'notify::rounded': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Bin.ConstructorProps {
                start_at: number;
                startAt: number;
                end_at: number;
                endAt: number;
                value: number;
                inverted: boolean;
                rounded: boolean;
            }
        }

        /**
         * CircularProgress is a subclass of [class`Gtk`.Bin] which provides a circular progress bar with customizable properties such as starting
         * and ending points, progress value, and visual features like rounded ends and inversion of progress direction.
         */
        class CircularProgress extends Gtk.Bin {
            static $gtype: GObject.GType<CircularProgress>;

            // Properties

            /**
             * The starting point of the progress circle, where 0 represents 3 o'clock position or 0° degrees and 1 represents 360°.
             */
            get start_at(): number;
            set start_at(val: number);
            /**
             * The starting point of the progress circle, where 0 represents 3 o'clock position or 0° degrees and 1 represents 360°.
             */
            get startAt(): number;
            set startAt(val: number);
            /**
             * The cutoff point of the background color of the progress circle.
             */
            get end_at(): number;
            set end_at(val: number);
            /**
             * The cutoff point of the background color of the progress circle.
             */
            get endAt(): number;
            set endAt(val: number);
            /**
             * The value which determines the arc of the drawn foreground color. Should be a value between 0 and 1.
             */
            get value(): number;
            set value(val: number);
            /**
             * Inverts the progress direction, making it draw counterclockwise.
             */
            get inverted(): boolean;
            set inverted(val: boolean);
            /**
             * Renders rounded ends at both the start and the end of the progress bar.
             */
            get rounded(): boolean;
            set rounded(val: boolean);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: CircularProgress.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<CircularProgress.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): CircularProgress;

            // Signals

            connect<K extends keyof CircularProgress.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, CircularProgress.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof CircularProgress.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, CircularProgress.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof CircularProgress.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<CircularProgress.SignalSignatures[K]> extends [any, ...infer Q]
                    ? Q
                    : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_start_at(): number;
            set_start_at(value: number): void;
            get_end_at(): number;
            set_end_at(value: number): void;
            get_value(): number;
            set_value(value: number): void;
            get_inverted(): boolean;
            set_inverted(value: boolean): void;
            get_rounded(): boolean;
            set_rounded(value: boolean): void;
        }

        namespace EventBox {
            // Signal signatures
            interface SignalSignatures extends Gtk.EventBox.SignalSignatures {
                hover: (arg0: HoverEvent) => void;
                'hover-lost': (arg0: HoverEvent) => void;
                click: (arg0: ClickEvent) => void;
                'click-release': (arg0: ClickEvent) => void;
                scroll: (arg0: ScrollEvent) => void;
                motion: (arg0: MotionEvent) => void;
                'notify::above-child': (pspec: GObject.ParamSpec) => void;
                'notify::visible-window': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.EventBox.ConstructorProps {}
        }

        /**
         * EventBox is a [class`Gtk`.EventBox] subclass which is meant to fix an issue with its [signal`Gtk`.Widget::enter_notify_event] and
         * [signal`Gtk`.Widget::leave_notify_event] when nesting EventBoxes
         * Its css selector is `eventbox`.
         */
        class EventBox extends Gtk.EventBox {
            static $gtype: GObject.GType<EventBox>;

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: EventBox.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<EventBox.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): EventBox;

            // Signals

            connect<K extends keyof EventBox.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, EventBox.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof EventBox.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, EventBox.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof EventBox.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<EventBox.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;
        }

        namespace Icon {
            // Signal signatures
            interface SignalSignatures extends Gtk.Image.SignalSignatures {
                'notify::pixbuf': (pspec: GObject.ParamSpec) => void;
                'notify::g-icon': (pspec: GObject.ParamSpec) => void;
                'notify::icon': (pspec: GObject.ParamSpec) => void;
                'notify::file': (pspec: GObject.ParamSpec) => void;
                'notify::gicon': (pspec: GObject.ParamSpec) => void;
                'notify::icon-name': (pspec: GObject.ParamSpec) => void;
                'notify::icon-set': (pspec: GObject.ParamSpec) => void;
                'notify::icon-size': (pspec: GObject.ParamSpec) => void;
                'notify::pixbuf-animation': (pspec: GObject.ParamSpec) => void;
                'notify::pixel-size': (pspec: GObject.ParamSpec) => void;
                'notify::resource': (pspec: GObject.ParamSpec) => void;
                'notify::stock': (pspec: GObject.ParamSpec) => void;
                'notify::storage-type': (pspec: GObject.ParamSpec) => void;
                'notify::surface': (pspec: GObject.ParamSpec) => void;
                'notify::use-fallback': (pspec: GObject.ParamSpec) => void;
                'notify::xalign': (pspec: GObject.ParamSpec) => void;
                'notify::xpad': (pspec: GObject.ParamSpec) => void;
                'notify::yalign': (pspec: GObject.ParamSpec) => void;
                'notify::ypad': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Image.ConstructorProps {
                pixbuf: GdkPixbuf.Pixbuf;
                g_icon: Gio.Icon;
                gIcon: Gio.Icon;
                icon: string;
            }
        }

        /**
         * [class`Gtk`.Image] subclass meant to be used only for icons.
         * It's size is calculated from `font-size` css property. Its css selector is `icon`.
         */
        class Icon extends Gtk.Image {
            static $gtype: GObject.GType<Icon>;

            // Properties

            get pixbuf(): GdkPixbuf.Pixbuf;
            set pixbuf(val: GdkPixbuf.Pixbuf);
            get g_icon(): Gio.Icon;
            set g_icon(val: Gio.Icon);
            get gIcon(): Gio.Icon;
            set gIcon(val: Gio.Icon);
            /**
             * Either a named icon or a path to a file.
             */
            get icon(): string;
            set icon(val: string);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Icon.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Icon.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Icon;

            // Signals

            connect<K extends keyof Icon.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Icon.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Icon.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Icon.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Icon.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Icon.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Static methods

            static lookup_icon(icon: string): Gtk.IconInfo | null;

            // Methods

            get_pixbuf(): GdkPixbuf.Pixbuf;
            // Conflicted with Gtk.Image.get_pixbuf
            get_pixbuf(...args: never[]): any;
            set_pixbuf(value: GdkPixbuf.Pixbuf): void;
            get_g_icon(): Gio.Icon;
            set_g_icon(value: Gio.Icon): void;
            get_icon(): string;
            set_icon(value: string): void;
        }

        namespace Label {
            // Signal signatures
            interface SignalSignatures extends Gtk.Label.SignalSignatures {
                'notify::truncate': (pspec: GObject.ParamSpec) => void;
                'notify::justify-fill': (pspec: GObject.ParamSpec) => void;
                'notify::angle': (pspec: GObject.ParamSpec) => void;
                'notify::attributes': (pspec: GObject.ParamSpec) => void;
                'notify::cursor-position': (pspec: GObject.ParamSpec) => void;
                'notify::ellipsize': (pspec: GObject.ParamSpec) => void;
                'notify::justify': (pspec: GObject.ParamSpec) => void;
                'notify::label': (pspec: GObject.ParamSpec) => void;
                'notify::lines': (pspec: GObject.ParamSpec) => void;
                'notify::max-width-chars': (pspec: GObject.ParamSpec) => void;
                'notify::mnemonic-keyval': (pspec: GObject.ParamSpec) => void;
                'notify::mnemonic-widget': (pspec: GObject.ParamSpec) => void;
                'notify::pattern': (pspec: GObject.ParamSpec) => void;
                'notify::selectable': (pspec: GObject.ParamSpec) => void;
                'notify::selection-bound': (pspec: GObject.ParamSpec) => void;
                'notify::single-line-mode': (pspec: GObject.ParamSpec) => void;
                'notify::track-visited-links': (pspec: GObject.ParamSpec) => void;
                'notify::use-markup': (pspec: GObject.ParamSpec) => void;
                'notify::use-underline': (pspec: GObject.ParamSpec) => void;
                'notify::width-chars': (pspec: GObject.ParamSpec) => void;
                'notify::wrap': (pspec: GObject.ParamSpec) => void;
                'notify::wrap-mode': (pspec: GObject.ParamSpec) => void;
                'notify::xalign': (pspec: GObject.ParamSpec) => void;
                'notify::yalign': (pspec: GObject.ParamSpec) => void;
                'notify::xpad': (pspec: GObject.ParamSpec) => void;
                'notify::ypad': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Label.ConstructorProps {
                truncate: boolean;
                justify_fill: boolean;
                justifyFill: boolean;
            }
        }

        class Label extends Gtk.Label {
            static $gtype: GObject.GType<Label>;

            // Properties

            /**
             * Shortcut for setting [property`Gtk`.Label:ellipsize] to [enum`Pango`.EllipsizeMode.END]
             */
            get truncate(): boolean;
            set truncate(val: boolean);
            /**
             * Shortcut for setting [property`Gtk`.Label:justify] to [enum`Gtk`.Justification.FILL]
             */
            get justify_fill(): boolean;
            set justify_fill(val: boolean);
            /**
             * Shortcut for setting [property`Gtk`.Label:justify] to [enum`Gtk`.Justification.FILL]
             */
            get justifyFill(): boolean;
            set justifyFill(val: boolean);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Label.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Label.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Label;

            // Signals

            connect<K extends keyof Label.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Label.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Label.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Label.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Label.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Label.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_truncate(): boolean;
            set_truncate(value: boolean): void;
            get_justify_fill(): boolean;
            set_justify_fill(value: boolean): void;
        }

        namespace LevelBar {
            // Signal signatures
            interface SignalSignatures extends Gtk.LevelBar.SignalSignatures {
                'notify::vertical': (pspec: GObject.ParamSpec) => void;
                'notify::inverted': (pspec: GObject.ParamSpec) => void;
                'notify::max-value': (pspec: GObject.ParamSpec) => void;
                'notify::min-value': (pspec: GObject.ParamSpec) => void;
                'notify::mode': (pspec: GObject.ParamSpec) => void;
                'notify::value': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.LevelBar.ConstructorProps {
                vertical: boolean;
            }
        }

        class LevelBar extends Gtk.LevelBar {
            static $gtype: GObject.GType<LevelBar>;

            // Properties

            /**
             * Corresponds to [property`Gtk`.Orientable :orientation].
             */
            get vertical(): boolean;
            set vertical(val: boolean);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: LevelBar.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<LevelBar.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): LevelBar;

            // Signals

            connect<K extends keyof LevelBar.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, LevelBar.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof LevelBar.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, LevelBar.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof LevelBar.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<LevelBar.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_vertical(): boolean;
            set_vertical(value: boolean): void;
        }

        namespace Overlay {
            // Signal signatures
            interface SignalSignatures extends Gtk.Overlay.SignalSignatures {
                'notify::pass-through': (pspec: GObject.ParamSpec) => void;
                'notify::overlay': (pspec: GObject.ParamSpec) => void;
                'notify::overlays': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Overlay.ConstructorProps {
                pass_through: boolean;
                passThrough: boolean;
                overlay: Gtk.Widget;
                overlays: Gtk.Widget[];
                child: Gtk.Widget;
            }
        }

        class Overlay extends Gtk.Overlay {
            static $gtype: GObject.GType<Overlay>;

            // Properties

            get pass_through(): boolean;
            set pass_through(val: boolean);
            get passThrough(): boolean;
            set passThrough(val: boolean);
            /**
             * First [property`Astal`.Overlay:overlays] element.
             * WARNING: setting this value will remove every overlay but the first.
             */
            get overlay(): Gtk.Widget;
            set overlay(val: Gtk.Widget);
            /**
             * Sets the overlays of this Overlay. [method`Gtk`.Overlay.add_overlay].
             */
            get overlays(): Gtk.Widget[];
            set overlays(val: Gtk.Widget[]);
            get child(): Gtk.Widget;
            set child(val: Gtk.Widget);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Overlay.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Overlay.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Overlay;

            // Signals

            connect<K extends keyof Overlay.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Overlay.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Overlay.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Overlay.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Overlay.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Overlay.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            add_overlay(widget: Gtk.Widget): void;
            get_pass_through(): boolean;
            set_pass_through(value: boolean): void;
            get_overlay(): Gtk.Widget | null;
            set_overlay(value?: Gtk.Widget | null): void;
            get_overlays(): Gtk.Widget[];
            set_overlays(value: Gtk.Widget[]): void;
            get_child(): Gtk.Widget | null;
            set_child(value?: Gtk.Widget | null): void;
        }

        namespace Scrollable {
            // Signal signatures
            interface SignalSignatures extends Gtk.ScrolledWindow.SignalSignatures {
                'notify::hscroll': (pspec: GObject.ParamSpec) => void;
                'notify::vscroll': (pspec: GObject.ParamSpec) => void;
                'notify::hadjustment': (pspec: GObject.ParamSpec) => void;
                'notify::hscrollbar-policy': (pspec: GObject.ParamSpec) => void;
                'notify::kinetic-scrolling': (pspec: GObject.ParamSpec) => void;
                'notify::max-content-height': (pspec: GObject.ParamSpec) => void;
                'notify::max-content-width': (pspec: GObject.ParamSpec) => void;
                'notify::min-content-height': (pspec: GObject.ParamSpec) => void;
                'notify::min-content-width': (pspec: GObject.ParamSpec) => void;
                'notify::overlay-scrolling': (pspec: GObject.ParamSpec) => void;
                'notify::propagate-natural-height': (pspec: GObject.ParamSpec) => void;
                'notify::propagate-natural-width': (pspec: GObject.ParamSpec) => void;
                'notify::shadow-type': (pspec: GObject.ParamSpec) => void;
                'notify::vadjustment': (pspec: GObject.ParamSpec) => void;
                'notify::vscrollbar-policy': (pspec: GObject.ParamSpec) => void;
                'notify::window-placement': (pspec: GObject.ParamSpec) => void;
                'notify::window-placement-set': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.ScrolledWindow.ConstructorProps {
                hscroll: Gtk.PolicyType;
                vscroll: Gtk.PolicyType;
            }
        }

        /**
         * Subclass of [class`Gtk`.ScrolledWindow] which has its policy default to [enum`Gtk`.PolicyType.AUTOMATIC].
         * Its css selector is `scrollable`. Its child getter returns the child of the inner [class`Gtk`.Viewport], instead of the viewport.
         */
        class Scrollable extends Gtk.ScrolledWindow {
            static $gtype: GObject.GType<Scrollable>;

            // Properties

            get hscroll(): Gtk.PolicyType;
            set hscroll(val: Gtk.PolicyType);
            get vscroll(): Gtk.PolicyType;
            set vscroll(val: Gtk.PolicyType);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Scrollable.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Scrollable.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Scrollable;

            // Signals

            connect<K extends keyof Scrollable.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Scrollable.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Scrollable.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Scrollable.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Scrollable.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Scrollable.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_child(): Gtk.Widget;
            // Conflicted with Gtk.Bin.get_child
            get_child(...args: never[]): any;
            get_hscroll(): Gtk.PolicyType;
            set_hscroll(value: Gtk.PolicyType | null): void;
            get_vscroll(): Gtk.PolicyType;
            set_vscroll(value: Gtk.PolicyType | null): void;
        }

        namespace Slider {
            // Signal signatures
            interface SignalSignatures extends Gtk.Scale.SignalSignatures {
                dragged: () => void;
                'notify::vertical': (pspec: GObject.ParamSpec) => void;
                'notify::dragging': (pspec: GObject.ParamSpec) => void;
                'notify::value': (pspec: GObject.ParamSpec) => void;
                'notify::min': (pspec: GObject.ParamSpec) => void;
                'notify::max': (pspec: GObject.ParamSpec) => void;
                'notify::step': (pspec: GObject.ParamSpec) => void;
                'notify::page': (pspec: GObject.ParamSpec) => void;
                'notify::digits': (pspec: GObject.ParamSpec) => void;
                'notify::draw-value': (pspec: GObject.ParamSpec) => void;
                'notify::has-origin': (pspec: GObject.ParamSpec) => void;
                'notify::value-pos': (pspec: GObject.ParamSpec) => void;
                'notify::adjustment': (pspec: GObject.ParamSpec) => void;
                'notify::fill-level': (pspec: GObject.ParamSpec) => void;
                'notify::inverted': (pspec: GObject.ParamSpec) => void;
                'notify::lower-stepper-sensitivity': (pspec: GObject.ParamSpec) => void;
                'notify::restrict-to-fill-level': (pspec: GObject.ParamSpec) => void;
                'notify::round-digits': (pspec: GObject.ParamSpec) => void;
                'notify::show-fill-level': (pspec: GObject.ParamSpec) => void;
                'notify::upper-stepper-sensitivity': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Scale.ConstructorProps {
                vertical: boolean;
                dragging: boolean;
                value: number;
                min: number;
                max: number;
                step: number;
                page: number;
            }
        }

        /**
         * Subclass of [class`Gtk`.Scale] which adds a signal and property for the drag state.
         */
        class Slider extends Gtk.Scale {
            static $gtype: GObject.GType<Slider>;

            // Properties

            /**
             * Corresponds to [property`Gtk`.Orientable :orientation].
             */
            get vertical(): boolean;
            set vertical(val: boolean);
            /**
             * `true` when the user drags the slider or uses keyboard arrows.
             */
            get dragging(): boolean;
            set dragging(val: boolean);
            /**
             * Value of this slider. Defaults to `0`.
             */
            get value(): number;
            set value(val: number);
            /**
             * Minimum possible value of this slider. Defaults to `0`.
             */
            get min(): number;
            set min(val: number);
            /**
             * Maximum possible value of this slider. Defaults to `1`.
             */
            get max(): number;
            set max(val: number);
            /**
             * Size of step increments. Defaults to `0.05`.
             */
            get step(): number;
            set step(val: number);
            /**
             * Size of page increments. Defaults to `0.01`.
             */
            get page(): number;
            set page(val: number);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Slider.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Slider.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Slider;

            // Signals

            connect<K extends keyof Slider.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Slider.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Slider.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Slider.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Slider.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Slider.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_vertical(): boolean;
            set_vertical(value: boolean): void;
            get_dragging(): boolean;
            get_value(): number;
            set_value(value: number): void;
            get_min(): number;
            set_min(value: number): void;
            get_max(): number;
            set_max(value: number): void;
            get_step(): number;
            set_step(value: number): void;
            get_page(): number;
            set_page(value: number): void;
        }

        namespace Stack {
            // Signal signatures
            interface SignalSignatures extends Gtk.Stack.SignalSignatures {
                'notify::shown': (pspec: GObject.ParamSpec) => void;
                'notify::children': (pspec: GObject.ParamSpec) => void;
                'notify::hhomogeneous': (pspec: GObject.ParamSpec) => void;
                'notify::homogeneous': (pspec: GObject.ParamSpec) => void;
                'notify::interpolate-size': (pspec: GObject.ParamSpec) => void;
                'notify::transition-duration': (pspec: GObject.ParamSpec) => void;
                'notify::transition-running': (pspec: GObject.ParamSpec) => void;
                'notify::transition-type': (pspec: GObject.ParamSpec) => void;
                'notify::vhomogeneous': (pspec: GObject.ParamSpec) => void;
                'notify::visible-child': (pspec: GObject.ParamSpec) => void;
                'notify::visible-child-name': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Stack.ConstructorProps {
                shown: string;
                children: Gtk.Widget[];
            }
        }

        /**
         * Subclass of [class`Gtk`.Stack] that has a children setter which invokes [method`Gt`.Stack.add_named] with the child's [property
         * `Gtk`.Widget:name] property.
         */
        class Stack extends Gtk.Stack {
            static $gtype: GObject.GType<Stack>;

            // Properties

            /**
             * Same as [property`Gtk`.Stack:visible-child-name].
             */
            get shown(): string;
            set shown(val: string);
            get children(): Gtk.Widget[];
            set children(val: Gtk.Widget[]);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Stack.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Stack.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Stack;

            // Signals

            connect<K extends keyof Stack.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Stack.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Stack.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Stack.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Stack.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Stack.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_shown(): string;
            set_shown(value: string): void;
            get_children(): Gtk.Widget[];
            set_children(value: Gtk.Widget[]): void;
        }

        namespace Window {
            // Signal signatures
            interface SignalSignatures extends Gtk.Window.SignalSignatures {
                'notify::inhibit': (pspec: GObject.ParamSpec) => void;
                'notify::namespace': (pspec: GObject.ParamSpec) => void;
                'notify::anchor': (pspec: GObject.ParamSpec) => void;
                'notify::exclusivity': (pspec: GObject.ParamSpec) => void;
                'notify::layer': (pspec: GObject.ParamSpec) => void;
                'notify::keymode': (pspec: GObject.ParamSpec) => void;
                'notify::gdkmonitor': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-left': (pspec: GObject.ParamSpec) => void;
                'notify::margin-right': (pspec: GObject.ParamSpec) => void;
                'notify::margin': (pspec: GObject.ParamSpec) => void;
                'notify::monitor': (pspec: GObject.ParamSpec) => void;
                'notify::accept-focus': (pspec: GObject.ParamSpec) => void;
                'notify::application': (pspec: GObject.ParamSpec) => void;
                'notify::attached-to': (pspec: GObject.ParamSpec) => void;
                'notify::decorated': (pspec: GObject.ParamSpec) => void;
                'notify::default-height': (pspec: GObject.ParamSpec) => void;
                'notify::default-width': (pspec: GObject.ParamSpec) => void;
                'notify::deletable': (pspec: GObject.ParamSpec) => void;
                'notify::destroy-with-parent': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-map': (pspec: GObject.ParamSpec) => void;
                'notify::focus-visible': (pspec: GObject.ParamSpec) => void;
                'notify::gravity': (pspec: GObject.ParamSpec) => void;
                'notify::has-resize-grip': (pspec: GObject.ParamSpec) => void;
                'notify::has-toplevel-focus': (pspec: GObject.ParamSpec) => void;
                'notify::hide-titlebar-when-maximized': (pspec: GObject.ParamSpec) => void;
                'notify::icon': (pspec: GObject.ParamSpec) => void;
                'notify::icon-name': (pspec: GObject.ParamSpec) => void;
                'notify::is-active': (pspec: GObject.ParamSpec) => void;
                'notify::is-maximized': (pspec: GObject.ParamSpec) => void;
                'notify::mnemonics-visible': (pspec: GObject.ParamSpec) => void;
                'notify::modal': (pspec: GObject.ParamSpec) => void;
                'notify::resizable': (pspec: GObject.ParamSpec) => void;
                'notify::resize-grip-visible': (pspec: GObject.ParamSpec) => void;
                'notify::role': (pspec: GObject.ParamSpec) => void;
                'notify::screen': (pspec: GObject.ParamSpec) => void;
                'notify::skip-pager-hint': (pspec: GObject.ParamSpec) => void;
                'notify::skip-taskbar-hint': (pspec: GObject.ParamSpec) => void;
                'notify::startup-id': (pspec: GObject.ParamSpec) => void;
                'notify::title': (pspec: GObject.ParamSpec) => void;
                'notify::transient-for': (pspec: GObject.ParamSpec) => void;
                'notify::type': (pspec: GObject.ParamSpec) => void;
                'notify::type-hint': (pspec: GObject.ParamSpec) => void;
                'notify::urgency-hint': (pspec: GObject.ParamSpec) => void;
                'notify::window-position': (pspec: GObject.ParamSpec) => void;
                'notify::border-width': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::resize-mode': (pspec: GObject.ParamSpec) => void;
                'notify::app-paintable': (pspec: GObject.ParamSpec) => void;
                'notify::can-default': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::composite-child': (pspec: GObject.ParamSpec) => void;
                'notify::double-buffered': (pspec: GObject.ParamSpec) => void;
                'notify::events': (pspec: GObject.ParamSpec) => void;
                'notify::expand': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::is-focus': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::no-show-all': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::style': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
                'notify::window': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Window.ConstructorProps {
                inhibit: boolean;
                namespace: string;
                anchor: WindowAnchor;
                exclusivity: Exclusivity;
                layer: Layer;
                keymode: Keymode;
                gdkmonitor: Gdk.Monitor;
                margin_top: number;
                marginTop: number;
                margin_bottom: number;
                marginBottom: number;
                margin_left: number;
                marginLeft: number;
                margin_right: number;
                marginRight: number;
                margin: number;
                monitor: number;
            }
        }

        /**
         * Subclass of [class`Gtk`.Window] which integrates GtkLayerShell as class fields.
         */
        class Window extends Gtk.Window {
            static $gtype: GObject.GType<Window>;

            // Properties

            /**
             * When `true` it will permit inhibiting the idle behavior such as screen blanking, locking, and screensaving.
             */
            get inhibit(): boolean;
            set inhibit(val: boolean);
            /**
             * Namespace of this window. This can be used to target the layer in compositor rules.
             */
            get namespace(): string;
            set namespace(val: string);
            /**
             * Edges to anchor the window to.
             * If two perpendicular edges are anchored, the surface will be anchored to that corner. If two opposite edges are anchored, the window will be
             * stretched across the screen in that direction.
             */
            get anchor(): WindowAnchor;
            set anchor(val: WindowAnchor);
            /**
             * Exclusivity of this window.
             */
            get exclusivity(): Exclusivity;
            set exclusivity(val: Exclusivity);
            /**
             * Which layer to appear this window on.
             */
            get layer(): Layer;
            set layer(val: Layer);
            /**
             * Keyboard mode of this window.
             */
            get keymode(): Keymode;
            set keymode(val: Keymode);
            /**
             * Which monitor to appear this window on.
             */
            get gdkmonitor(): Gdk.Monitor;
            set gdkmonitor(val: Gdk.Monitor);
            get margin_top(): number;
            set margin_top(val: number);
            get marginTop(): number;
            set marginTop(val: number);
            get margin_bottom(): number;
            set margin_bottom(val: number);
            get marginBottom(): number;
            set marginBottom(val: number);
            get margin_left(): number;
            set margin_left(val: number);
            get marginLeft(): number;
            set marginLeft(val: number);
            get margin_right(): number;
            set margin_right(val: number);
            get marginRight(): number;
            set marginRight(val: number);
            set margin(val: number);
            /**
             * Which monitor to appear this window on.
             * CAUTION: the id might not be the same mapped by the compositor.
             */
            get monitor(): number;
            set monitor(val: number);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Window.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Window.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Window;

            // Signals

            connect<K extends keyof Window.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Window.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Window.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Window.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Window.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Window.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            /**
             * Get the current [class`Gdk`.Monitor] this window resides in.
             */
            get_current_monitor(): Gdk.Monitor;
            get_inhibit(): boolean;
            set_inhibit(value: boolean): void;
            get_namespace(): string;
            set_namespace(value: string): void;
            get_anchor(): WindowAnchor;
            set_anchor(value: WindowAnchor | null): void;
            get_exclusivity(): Exclusivity;
            set_exclusivity(value: Exclusivity | null): void;
            get_layer(): Layer;
            set_layer(value: Layer | null): void;
            get_keymode(): Keymode;
            set_keymode(value: Keymode | null): void;
            get_gdkmonitor(): Gdk.Monitor;
            set_gdkmonitor(value: Gdk.Monitor): void;
            get_margin_top(): number;
            set_margin_top(value: number): void;
            get_margin_bottom(): number;
            set_margin_bottom(value: number): void;
            get_margin_left(): number;
            set_margin_left(value: number): void;
            get_margin_right(): number;
            set_margin_right(value: number): void;
            set_margin(value: number): void;
            get_monitor(): number;
            set_monitor(value: number): void;
        }

        namespace Application {
            // Signal signatures
            interface SignalSignatures extends Gtk.Application.SignalSignatures {
                'monitor-added': (arg0: Gdk.Monitor) => void;
                'monitor-removed': (arg0: Gdk.Monitor) => void;
                'window-toggled': (arg0: Gtk.Window) => void;
                'notify::monitors': (pspec: GObject.ParamSpec) => void;
                'notify::windows': (pspec: GObject.ParamSpec) => void;
                'notify::gtk-theme': (pspec: GObject.ParamSpec) => void;
                'notify::icon-theme': (pspec: GObject.ParamSpec) => void;
                'notify::cursor-theme': (pspec: GObject.ParamSpec) => void;
                'notify::active-window': (pspec: GObject.ParamSpec) => void;
                'notify::app-menu': (pspec: GObject.ParamSpec) => void;
                'notify::menubar': (pspec: GObject.ParamSpec) => void;
                'notify::register-session': (pspec: GObject.ParamSpec) => void;
                'notify::screensaver-active': (pspec: GObject.ParamSpec) => void;
                'notify::action-group': (pspec: GObject.ParamSpec) => void;
                'notify::application-id': (pspec: GObject.ParamSpec) => void;
                'notify::flags': (pspec: GObject.ParamSpec) => void;
                'notify::inactivity-timeout': (pspec: GObject.ParamSpec) => void;
                'notify::is-busy': (pspec: GObject.ParamSpec) => void;
                'notify::is-registered': (pspec: GObject.ParamSpec) => void;
                'notify::is-remote': (pspec: GObject.ParamSpec) => void;
                'notify::resource-base-path': (pspec: GObject.ParamSpec) => void;
                'notify::version': (pspec: GObject.ParamSpec) => void;
                'notify::instance-name': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Application.ConstructorProps, AstalIO.Application.ConstructorProps {
                monitors: Gdk.Monitor[];
                windows: Gtk.Window[];
                gtk_theme: string;
                gtkTheme: string;
                icon_theme: string;
                iconTheme: string;
                cursor_theme: string;
                cursorTheme: string;
            }
        }

        class Application extends Gtk.Application implements AstalIO.Application {
            static $gtype: GObject.GType<Application>;

            // Properties

            /**
             * Get all monitors from [class`Gdk`.Display].
             */
            get monitors(): Gdk.Monitor[];
            /**
             * Windows that has been added to this app using [method`Gtk`.Application.add_window].
             */
            get windows(): Gtk.Window[];
            /**
             * Shortcut for [property`Gtk`.Settings:gtk_theme_name]
             */
            get gtk_theme(): string;
            set gtk_theme(val: string);
            /**
             * Shortcut for [property`Gtk`.Settings:gtk_theme_name]
             */
            get gtkTheme(): string;
            set gtkTheme(val: string);
            /**
             * Shortcut for [property`Gtk`.Settings:gtk_icon_theme_name]
             */
            get icon_theme(): string;
            set icon_theme(val: string);
            /**
             * Shortcut for [property`Gtk`.Settings:gtk_icon_theme_name]
             */
            get iconTheme(): string;
            set iconTheme(val: string);
            /**
             * Shortcut for [property`Gtk`.Settings:gtk_cursor_theme_name]
             */
            get cursor_theme(): string;
            set cursor_theme(val: string);
            /**
             * Shortcut for [property`Gtk`.Settings:gtk_cursor_theme_name]
             */
            get cursorTheme(): string;
            set cursorTheme(val: string);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Application.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Application.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Application;

            // Signals

            connect<K extends keyof Application.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Application.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Application.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Application.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Application.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Application.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Virtual methods

            /**
             * Handler for an incoming request.
             * @param request Body of the request
             * @param conn The connection which expects the response.
             */
            vfunc_request(request: string, conn: Gio.SocketConnection): void;

            // Methods

            /**
             * Remove all [class`Gtk`.StyleContext] providers.
             */
            reset_css(): void;
            /**
             * Get a window by its [property`Gtk`.Widget:name] that has been added to this app using [method`Gtk`.Application.add_window].
             * @param name
             */
            get_window(name: string): Gtk.Window | null;
            /**
             * Add a new [class`Gtk`.StyleContext] provider.
             * @param style Css string or a path to a css file.
             * @param reset
             */
            apply_css(style: string, reset: boolean): void;
            /**
             * Shortcut for [method`Gtk`.IconTheme.prepend_search_path].
             * @param path
             */
            add_icons(path?: string | null): void;
            /**
             * Handler for an incoming request.
             * @param request Body of the request
             * @param conn The connection which expects the response.
             */
            request(request: string, conn: Gio.SocketConnection): void;
            get_monitors(): Gdk.Monitor[];
            get_windows(): Gtk.Window[];
            get_gtk_theme(): string;
            set_gtk_theme(value: string): void;
            get_icon_theme(): string;
            set_icon_theme(value: string): void;
            get_cursor_theme(): string;
            set_cursor_theme(value: string): void;

            // Inherited properties
            get instance_name(): string;
            set instance_name(val: string);
            get instanceName(): string;
            set instanceName(val: string);

            // Inherited methods
            quit(): void;
            inspector(): void;
            toggle_window(window: string): void;
            acquire_socket(): void;
            get_instance_name(): string;
            set_instance_name(value: string): void;
            vfunc_quit(): void;
            vfunc_inspector(): void;
            vfunc_toggle_window(window: string): void;
            vfunc_acquire_socket(): void;
            vfunc_get_instance_name(): string;
            vfunc_set_instance_name(value: string): void;
            /**
             * Creates a binding between `source_property` on `source` and `target_property`
             * on `target`.
             *
             * Whenever the `source_property` is changed the `target_property` is
             * updated using the same value. For instance:
             *
             *
             * ```c
             *   g_object_bind_property (action, "active", widget, "sensitive", 0);
             * ```
             *
             *
             * Will result in the "sensitive" property of the widget #GObject instance to be
             * updated with the same value of the "active" property of the action #GObject
             * instance.
             *
             * If `flags` contains %G_BINDING_BIDIRECTIONAL then the binding will be mutual:
             * if `target_property` on `target` changes then the `source_property` on `source`
             * will be updated as well.
             *
             * The binding will automatically be removed when either the `source` or the
             * `target` instances are finalized. To remove the binding without affecting the
             * `source` and the `target` you can just call g_object_unref() on the returned
             * #GBinding instance.
             *
             * Removing the binding by calling g_object_unref() on it must only be done if
             * the binding, `source` and `target` are only used from a single thread and it
             * is clear that both `source` and `target` outlive the binding. Especially it
             * is not safe to rely on this if the binding, `source` or `target` can be
             * finalized from different threads. Keep another reference to the binding and
             * use g_binding_unbind() instead to be on the safe side.
             *
             * A #GObject can have multiple bindings.
             * @param source_property the property on @source to bind
             * @param target the target #GObject
             * @param target_property the property on @target to bind
             * @param flags flags to pass to #GBinding
             * @returns the #GBinding instance representing the     binding between the two #GObject instances. The binding is released     whenever the #GBinding reference count reaches zero.
             */
            bind_property(
                source_property: string,
                target: GObject.Object,
                target_property: string,
                flags: GObject.BindingFlags | null,
            ): GObject.Binding;
            /**
             * Complete version of g_object_bind_property().
             *
             * Creates a binding between `source_property` on `source` and `target_property`
             * on `target,` allowing you to set the transformation functions to be used by
             * the binding.
             *
             * If `flags` contains %G_BINDING_BIDIRECTIONAL then the binding will be mutual:
             * if `target_property` on `target` changes then the `source_property` on `source`
             * will be updated as well. The `transform_from` function is only used in case
             * of bidirectional bindings, otherwise it will be ignored
             *
             * The binding will automatically be removed when either the `source` or the
             * `target` instances are finalized. This will release the reference that is
             * being held on the #GBinding instance; if you want to hold on to the
             * #GBinding instance, you will need to hold a reference to it.
             *
             * To remove the binding, call g_binding_unbind().
             *
             * A #GObject can have multiple bindings.
             *
             * The same `user_data` parameter will be used for both `transform_to`
             * and `transform_from` transformation functions; the `notify` function will
             * be called once, when the binding is removed. If you need different data
             * for each transformation function, please use
             * g_object_bind_property_with_closures() instead.
             * @param source_property the property on @source to bind
             * @param target the target #GObject
             * @param target_property the property on @target to bind
             * @param flags flags to pass to #GBinding
             * @param transform_to the transformation function     from the @source to the @target, or %NULL to use the default
             * @param transform_from the transformation function     from the @target to the @source, or %NULL to use the default
             * @param notify a function to call when disposing the binding, to free     resources used by the transformation functions, or %NULL if not required
             * @returns the #GBinding instance representing the     binding between the two #GObject instances. The binding is released     whenever the #GBinding reference count reaches zero.
             */
            bind_property_full(
                source_property: string,
                target: GObject.Object,
                target_property: string,
                flags: GObject.BindingFlags | null,
                transform_to?: GObject.BindingTransformFunc | null,
                transform_from?: GObject.BindingTransformFunc | null,
                notify?: GLib.DestroyNotify | null,
            ): GObject.Binding;
            // Conflicted with GObject.Object.bind_property_full
            bind_property_full(...args: never[]): any;
            /**
             * This function is intended for #GObject implementations to re-enforce
             * a [floating][floating-ref] object reference. Doing this is seldom
             * required: all #GInitiallyUnowneds are created with a floating reference
             * which usually just needs to be sunken by calling g_object_ref_sink().
             */
            force_floating(): void;
            /**
             * Increases the freeze count on `object`. If the freeze count is
             * non-zero, the emission of "notify" signals on `object` is
             * stopped. The signals are queued until the freeze count is decreased
             * to zero. Duplicate notifications are squashed so that at most one
             * #GObject::notify signal is emitted for each property modified while the
             * object is frozen.
             *
             * This is necessary for accessors that modify multiple properties to prevent
             * premature notification while the object is still being modified.
             */
            freeze_notify(): void;
            /**
             * Gets a named field from the objects table of associations (see g_object_set_data()).
             * @param key name of the key for that association
             * @returns the data if found,          or %NULL if no such data exists.
             */
            get_data(key: string): any | null;
            /**
             * Gets a property of an object.
             *
             * The value can be:
             * - an empty GObject.Value initialized by G_VALUE_INIT, which will be automatically initialized with the expected type of the property (since GLib 2.60)
             * - a GObject.Value initialized with the expected type of the property
             * - a GObject.Value initialized with a type to which the expected type of the property can be transformed
             *
             * In general, a copy is made of the property contents and the caller is responsible for freeing the memory by calling GObject.Value.unset.
             *
             * Note that GObject.Object.get_property is really intended for language bindings, GObject.Object.get is much more convenient for C programming.
             * @param property_name The name of the property to get
             * @param value Return location for the property value. Can be an empty GObject.Value initialized by G_VALUE_INIT (auto-initialized with expected type since GLib 2.60), a GObject.Value initialized with the expected property type, or a GObject.Value initialized with a transformable type
             */
            get_property(property_name: string, value: GObject.Value | any): any;
            /**
             * This function gets back user data pointers stored via
             * g_object_set_qdata().
             * @param quark A #GQuark, naming the user data pointer
             * @returns The user data pointer set, or %NULL
             */
            get_qdata(quark: GLib.Quark): any | null;
            /**
             * Gets `n_properties` properties for an `object`.
             * Obtained properties will be set to `values`. All properties must be valid.
             * Warnings will be emitted and undefined behaviour may result if invalid
             * properties are passed in.
             * @param names the names of each property to get
             * @param values the values of each property to get
             */
            getv(names: string[], values: (GObject.Value | any)[]): void;
            /**
             * Checks whether `object` has a [floating][floating-ref] reference.
             * @returns %TRUE if @object has a floating reference
             */
            is_floating(): boolean;
            /**
             * Emits a "notify" signal for the property `property_name` on `object`.
             *
             * When possible, eg. when signaling a property change from within the class
             * that registered the property, you should use g_object_notify_by_pspec()
             * instead.
             *
             * Note that emission of the notify signal may be blocked with
             * g_object_freeze_notify(). In this case, the signal emissions are queued
             * and will be emitted (in reverse order) when g_object_thaw_notify() is
             * called.
             * @param property_name the name of a property installed on the class of @object.
             */
            notify(property_name: string): void;
            /**
             * Emits a "notify" signal for the property specified by `pspec` on `object`.
             *
             * This function omits the property name lookup, hence it is faster than
             * g_object_notify().
             *
             * One way to avoid using g_object_notify() from within the
             * class that registered the properties, and using g_object_notify_by_pspec()
             * instead, is to store the GParamSpec used with
             * g_object_class_install_property() inside a static array, e.g.:
             *
             *
             * ```c
             *   typedef enum
             *   {
             *     PROP_FOO = 1,
             *     PROP_LAST
             *   } MyObjectProperty;
             *
             *   static GParamSpec *properties[PROP_LAST];
             *
             *   static void
             *   my_object_class_init (MyObjectClass *klass)
             *   {
             *     properties[PROP_FOO] = g_param_spec_int ("foo", NULL, NULL,
             *                                              0, 100,
             *                                              50,
             *                                              G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
             *     g_object_class_install_property (gobject_class,
             *                                      PROP_FOO,
             *                                      properties[PROP_FOO]);
             *   }
             * ```
             *
             *
             * and then notify a change on the "foo" property with:
             *
             *
             * ```c
             *   g_object_notify_by_pspec (self, properties[PROP_FOO]);
             * ```
             *
             * @param pspec the #GParamSpec of a property installed on the class of @object.
             */
            notify_by_pspec(pspec: GObject.ParamSpec): void;
            /**
             * Increases the reference count of `object`.
             *
             * Since GLib 2.56, if `GLIB_VERSION_MAX_ALLOWED` is 2.56 or greater, the type
             * of `object` will be propagated to the return type (using the GCC typeof()
             * extension), so any casting the caller needs to do on the return type must be
             * explicit.
             * @returns the same @object
             */
            ref(): GObject.Object;
            /**
             * Increase the reference count of `object,` and possibly remove the
             * [floating][floating-ref] reference, if `object` has a floating reference.
             *
             * In other words, if the object is floating, then this call "assumes
             * ownership" of the floating reference, converting it to a normal
             * reference by clearing the floating flag while leaving the reference
             * count unchanged.  If the object is not floating, then this call
             * adds a new normal reference increasing the reference count by one.
             *
             * Since GLib 2.56, the type of `object` will be propagated to the return type
             * under the same conditions as for g_object_ref().
             * @returns @object
             */
            ref_sink(): GObject.Object;
            /**
             * Releases all references to other objects. This can be used to break
             * reference cycles.
             *
             * This function should only be called from object system implementations.
             */
            run_dispose(): void;
            /**
             * Each object carries around a table of associations from
             * strings to pointers.  This function lets you set an association.
             *
             * If the object already had an association with that name,
             * the old association will be destroyed.
             *
             * Internally, the `key` is converted to a #GQuark using g_quark_from_string().
             * This means a copy of `key` is kept permanently (even after `object` has been
             * finalized) — so it is recommended to only use a small, bounded set of values
             * for `key` in your program, to avoid the #GQuark storage growing unbounded.
             * @param key name of the key
             * @param data data to associate with that key
             */
            set_data(key: string, data?: any | null): void;
            /**
             * Sets a property on an object.
             * @param property_name The name of the property to set
             * @param value The value to set the property to
             */
            set_property(property_name: string, value: GObject.Value | any): void;
            /**
             * Remove a specified datum from the object's data associations,
             * without invoking the association's destroy handler.
             * @param key name of the key
             * @returns the data if found, or %NULL          if no such data exists.
             */
            steal_data(key: string): any | null;
            /**
             * This function gets back user data pointers stored via
             * g_object_set_qdata() and removes the `data` from object
             * without invoking its destroy() function (if any was
             * set).
             * Usually, calling this function is only required to update
             * user data pointers with a destroy notifier, for example:
             *
             * ```c
             * void
             * object_add_to_user_list (GObject     *object,
             *                          const gchar *new_string)
             * {
             *   // the quark, naming the object data
             *   GQuark quark_string_list = g_quark_from_static_string ("my-string-list");
             *   // retrieve the old string list
             *   GList *list = g_object_steal_qdata (object, quark_string_list);
             *
             *   // prepend new string
             *   list = g_list_prepend (list, g_strdup (new_string));
             *   // this changed 'list', so we need to set it again
             *   g_object_set_qdata_full (object, quark_string_list, list, free_string_list);
             * }
             * static void
             * free_string_list (gpointer data)
             * {
             *   GList *node, *list = data;
             *
             *   for (node = list; node; node = node->next)
             *     g_free (node->data);
             *   g_list_free (list);
             * }
             * ```
             *
             * Using g_object_get_qdata() in the above example, instead of
             * g_object_steal_qdata() would have left the destroy function set,
             * and thus the partial string list would have been freed upon
             * g_object_set_qdata_full().
             * @param quark A #GQuark, naming the user data pointer
             * @returns The user data pointer set, or %NULL
             */
            steal_qdata(quark: GLib.Quark): any | null;
            /**
             * Reverts the effect of a previous call to
             * g_object_freeze_notify(). The freeze count is decreased on `object`
             * and when it reaches zero, queued "notify" signals are emitted.
             *
             * Duplicate notifications for each property are squashed so that at most one
             * #GObject::notify signal is emitted for each property, in the reverse order
             * in which they have been queued.
             *
             * It is an error to call this function when the freeze count is zero.
             */
            thaw_notify(): void;
            /**
             * Decreases the reference count of `object`. When its reference count
             * drops to 0, the object is finalized (i.e. its memory is freed).
             *
             * If the pointer to the #GObject may be reused in future (for example, if it is
             * an instance variable of another object), it is recommended to clear the
             * pointer to %NULL rather than retain a dangling pointer to a potentially
             * invalid #GObject instance. Use g_clear_object() for this.
             */
            unref(): void;
            /**
             * This function essentially limits the life time of the `closure` to
             * the life time of the object. That is, when the object is finalized,
             * the `closure` is invalidated by calling g_closure_invalidate() on
             * it, in order to prevent invocations of the closure with a finalized
             * (nonexisting) object. Also, g_object_ref() and g_object_unref() are
             * added as marshal guards to the `closure,` to ensure that an extra
             * reference count is held on `object` during invocation of the
             * `closure`.  Usually, this function will be called on closures that
             * use this `object` as closure data.
             * @param closure #GClosure to watch
             */
            watch_closure(closure: GObject.Closure): void;
            /**
             * the `constructed` function is called by g_object_new() as the
             *  final step of the object creation process.  At the point of the call, all
             *  construction properties have been set on the object.  The purpose of this
             *  call is to allow for object initialisation steps that can only be performed
             *  after construction properties have been set.  `constructed` implementors
             *  should chain up to the `constructed` call of their parent class to allow it
             *  to complete its initialisation.
             */
            vfunc_constructed(): void;
            /**
             * emits property change notification for a bunch
             *  of properties. Overriding `dispatch_properties_changed` should be rarely
             *  needed.
             * @param n_pspecs
             * @param pspecs
             */
            vfunc_dispatch_properties_changed(n_pspecs: number, pspecs: GObject.ParamSpec): void;
            /**
             * the `dispose` function is supposed to drop all references to other
             *  objects, but keep the instance otherwise intact, so that client method
             *  invocations still work. It may be run multiple times (due to reference
             *  loops). Before returning, `dispose` should chain up to the `dispose` method
             *  of the parent class.
             */
            vfunc_dispose(): void;
            /**
             * instance finalization function, should finish the finalization of
             *  the instance begun in `dispose` and chain up to the `finalize` method of the
             *  parent class.
             */
            vfunc_finalize(): void;
            /**
             * the generic getter for all properties of this type. Should be
             *  overridden for every type with properties.
             * @param property_id
             * @param value
             * @param pspec
             */
            vfunc_get_property(property_id: number, value: GObject.Value | any, pspec: GObject.ParamSpec): void;
            /**
             * Emits a "notify" signal for the property `property_name` on `object`.
             *
             * When possible, eg. when signaling a property change from within the class
             * that registered the property, you should use g_object_notify_by_pspec()
             * instead.
             *
             * Note that emission of the notify signal may be blocked with
             * g_object_freeze_notify(). In this case, the signal emissions are queued
             * and will be emitted (in reverse order) when g_object_thaw_notify() is
             * called.
             * @param pspec
             */
            vfunc_notify(pspec: GObject.ParamSpec): void;
            /**
             * the generic setter for all properties of this type. Should be
             *  overridden for every type with properties. If implementations of
             *  `set_property` don't emit property change notification explicitly, this will
             *  be done implicitly by the type system. However, if the notify signal is
             *  emitted explicitly, the type system will not emit it a second time.
             * @param property_id
             * @param value
             * @param pspec
             */
            vfunc_set_property(property_id: number, value: GObject.Value | any, pspec: GObject.ParamSpec): void;
            /**
             * Disconnects a handler from an instance so it will not be called during any future or currently ongoing emissions of the signal it has been connected to.
             * @param id Handler ID of the handler to be disconnected
             */
            disconnect(id: number): void;
            /**
             * Sets multiple properties of an object at once. The properties argument should be a dictionary mapping property names to values.
             * @param properties Object containing the properties to set
             */
            set(properties: { [key: string]: any }): void;
            /**
             * Blocks a handler of an instance so it will not be called during any signal emissions
             * @param id Handler ID of the handler to be blocked
             */
            block_signal_handler(id: number): void;
            /**
             * Unblocks a handler so it will be called again during any signal emissions
             * @param id Handler ID of the handler to be unblocked
             */
            unblock_signal_handler(id: number): void;
            /**
             * Stops a signal's emission by the given signal name. This will prevent the default handler and any subsequent signal handlers from being invoked.
             * @param detailedName Name of the signal to stop emission of
             */
            stop_emission_by_name(detailedName: string): void;
        }

        type BoxClass = typeof Box;
        abstract class BoxPrivate {
            static $gtype: GObject.GType<BoxPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type ButtonClass = typeof Button;
        abstract class ButtonPrivate {
            static $gtype: GObject.GType<ButtonPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type CenterBoxClass = typeof CenterBox;
        abstract class CenterBoxPrivate {
            static $gtype: GObject.GType<CenterBoxPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type CircularProgressClass = typeof CircularProgress;
        abstract class CircularProgressPrivate {
            static $gtype: GObject.GType<CircularProgressPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type EventBoxClass = typeof EventBox;
        abstract class EventBoxPrivate {
            static $gtype: GObject.GType<EventBoxPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type IconClass = typeof Icon;
        abstract class IconPrivate {
            static $gtype: GObject.GType<IconPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type LabelClass = typeof Label;
        abstract class LabelPrivate {
            static $gtype: GObject.GType<LabelPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type LevelBarClass = typeof LevelBar;
        abstract class LevelBarPrivate {
            static $gtype: GObject.GType<LevelBarPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type OverlayClass = typeof Overlay;
        abstract class OverlayPrivate {
            static $gtype: GObject.GType<OverlayPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type ScrollableClass = typeof Scrollable;
        abstract class ScrollablePrivate {
            static $gtype: GObject.GType<ScrollablePrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type SliderClass = typeof Slider;
        abstract class SliderPrivate {
            static $gtype: GObject.GType<SliderPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type StackClass = typeof Stack;
        abstract class StackPrivate {
            static $gtype: GObject.GType<StackPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type WindowClass = typeof Window;
        abstract class WindowPrivate {
            static $gtype: GObject.GType<WindowPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type ApplicationClass = typeof Application;
        abstract class ApplicationPrivate {
            static $gtype: GObject.GType<ApplicationPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        /**
         * Struct for [struct`Gdk`.EventButton]
         */
        class ClickEvent {
            static $gtype: GObject.GType<ClickEvent>;

            // Fields

            release: boolean;
            time: number;
            x: number;
            y: number;
            modifier: Gdk.ModifierType;
            button: MouseButton;

            // Constructors

            _init(...args: any[]): void;

            // Methods

            init(event: Gdk.EventButton): void;
        }

        /**
         * Struct for [struct`Gdk`.EventCrossing]
         */
        class HoverEvent {
            static $gtype: GObject.GType<HoverEvent>;

            // Fields

            lost: boolean;
            time: number;
            x: number;
            y: number;
            modifier: Gdk.ModifierType;
            mode: Gdk.CrossingMode;
            detail: Gdk.NotifyType;

            // Constructors

            _init(...args: any[]): void;

            // Methods

            init(event: Gdk.EventCrossing): void;
        }

        /**
         * Struct for [struct`Gdk`.EventScroll]
         */
        class ScrollEvent {
            static $gtype: GObject.GType<ScrollEvent>;

            // Fields

            time: number;
            x: number;
            y: number;
            modifier: Gdk.ModifierType;
            direction: Gdk.ScrollDirection;
            delta_x: number;
            delta_y: number;

            // Constructors

            _init(...args: any[]): void;

            // Methods

            init(event: Gdk.EventScroll): void;
        }

        /**
         * Struct for [struct`Gdk`.EventMotion]
         */
        class MotionEvent {
            static $gtype: GObject.GType<MotionEvent>;

            // Fields

            time: number;
            x: number;
            y: number;
            modifier: Gdk.ModifierType;

            // Constructors

            _init(...args: any[]): void;

            // Methods

            init(event: Gdk.EventMotion): void;
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

    export default Astal;
}

declare module 'gi://Astal' {
    import Astal30 from 'gi://Astal?version=3.0';
    export default Astal30;
}
// END
