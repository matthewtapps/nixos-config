/// <reference path="./gio-2.0.d.ts" />
/// <reference path="./gobject-2.0.d.ts" />
/// <reference path="./glib-2.0.d.ts" />
/// <reference path="./gmodule-2.0.d.ts" />
/// <reference path="./astalio-0.1.d.ts" />
/// <reference path="./gdk-4.0.d.ts" />
/// <reference path="./cairo-1.0.d.ts" />
/// <reference path="./cairo.d.ts" />
/// <reference path="./pangocairo-1.0.d.ts" />
/// <reference path="./pango-1.0.d.ts" />
/// <reference path="./harfbuzz-0.0.d.ts" />
/// <reference path="./freetype2-2.0.d.ts" />
/// <reference path="./gdkpixbuf-2.0.d.ts" />
/// <reference path="./gtk-4.0.d.ts" />
/// <reference path="./gsk-4.0.d.ts" />
/// <reference path="./graphene-1.0.d.ts" />

/**
 * Type Definitions for Gjs (https://gjs.guide/)
 *
 * These type definitions are automatically generated, do not edit them by hand.
 * If you found a bug fix it in `ts-for-gir` or create a bug report on https://github.com/gjsify/ts-for-gir
 *
 * The based EJS template file is used for the generated .d.ts file of each GIR module like Gtk-4.0, GObject-2.0, ...
 */

declare module 'gi://Astal?version=4.0' {
    // Module dependencies
    import type Gio from 'gi://Gio?version=2.0';
    import type GObject from 'gi://GObject?version=2.0';
    import type GLib from 'gi://GLib?version=2.0';
    import type GModule from 'gi://GModule?version=2.0';
    import type AstalIO from 'gi://AstalIO?version=0.1';
    import type Gdk from 'gi://Gdk?version=4.0';
    import type cairo from 'cairo';
    import type PangoCairo from 'gi://PangoCairo?version=1.0';
    import type Pango from 'gi://Pango?version=1.0';
    import type HarfBuzz from 'gi://HarfBuzz?version=0.0';
    import type freetype2 from 'gi://freetype2?version=2.0';
    import type GdkPixbuf from 'gi://GdkPixbuf?version=2.0';
    import type Gtk from 'gi://Gtk?version=4.0';
    import type Gsk from 'gi://Gsk?version=4.0';
    import type Graphene from 'gi://Graphene?version=1.0';

    export namespace Astal {
        /**
         * Astal-4.0
         */

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
        namespace Bin {
            // Signal signatures
            interface SignalSignatures extends Gtk.Widget.SignalSignatures {
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::can-target': (pspec: GObject.ParamSpec) => void;
                'notify::css-classes': (pspec: GObject.ParamSpec) => void;
                'notify::css-name': (pspec: GObject.ParamSpec) => void;
                'notify::cursor': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::focusable': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::layout-manager': (pspec: GObject.ParamSpec) => void;
                'notify::limit-events': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::overflow': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::root': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Widget.ConstructorProps, Gtk.Buildable.ConstructorProps {
                child: Gtk.Widget;
            }
        }

        /**
         * A widget with one child. It is useful for deriving subclasses, since it provides common code needed for handling a single child widget.
         */
        class Bin extends Gtk.Widget implements Gtk.Buildable {
            static $gtype: GObject.GType<Bin>;

            // Properties

            get child(): Gtk.Widget;
            set child(val: Gtk.Widget);

            /**
             * Compile-time signal type information.
             *
             * This instance property is generated only for TypeScript type checking.
             * It is not defined at runtime and should not be accessed in JS code.
             * @internal
             */
            $signals: Bin.SignalSignatures;

            // Constructors

            constructor(properties?: Partial<Bin.ConstructorProps>, ...args: any[]);

            _init(...args: any[]): void;

            static ['new'](): Bin;

            // Signals

            connect<K extends keyof Bin.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Bin.SignalSignatures[K]>,
            ): number;
            connect(signal: string, callback: (...args: any[]) => any): number;
            connect_after<K extends keyof Bin.SignalSignatures>(
                signal: K,
                callback: GObject.SignalCallback<this, Bin.SignalSignatures[K]>,
            ): number;
            connect_after(signal: string, callback: (...args: any[]) => any): number;
            emit<K extends keyof Bin.SignalSignatures>(
                signal: K,
                ...args: GObject.GjsParameters<Bin.SignalSignatures[K]> extends [any, ...infer Q] ? Q : never
            ): void;
            emit(signal: string, ...args: any[]): void;

            // Methods

            get_child(): Gtk.Widget | null;
            set_child(value?: Gtk.Widget | null): void;

            // Inherited methods
            /**
             * Gets the ID of the `buildable` object.
             *
             * `GtkBuilder` sets the name based on the ID attribute
             * of the `<object>` tag used to construct the `buildable`.
             * @returns the ID of the buildable object
             */
            get_buildable_id(): string | null;
            /**
             * Adds a child to `buildable`. `type` is an optional string
             * describing how the child should be added.
             * @param builder a `GtkBuilder`
             * @param child child to add
             * @param type kind of child or %NULL
             */
            vfunc_add_child(builder: Gtk.Builder, child: GObject.Object, type?: string | null): void;
            /**
             * Similar to gtk_buildable_parser_finished() but is
             * called once for each custom tag handled by the `buildable`.
             * @param builder a `GtkBuilder`
             * @param child child object or %NULL for non-child tags
             * @param tagname the name of the tag
             * @param data user data created in custom_tag_start
             */
            vfunc_custom_finished(
                builder: Gtk.Builder,
                child: GObject.Object | null,
                tagname: string,
                data?: any | null,
            ): void;
            /**
             * Called at the end of each custom element handled by
             * the buildable.
             * @param builder `GtkBuilder` used to construct this object
             * @param child child object or %NULL for non-child tags
             * @param tagname name of tag
             * @param data user data that will be passed in to parser functions
             */
            vfunc_custom_tag_end(
                builder: Gtk.Builder,
                child: GObject.Object | null,
                tagname: string,
                data?: any | null,
            ): void;
            /**
             * Called for each unknown element under `<child>`.
             * @param builder a `GtkBuilder` used to construct this object
             * @param child child object or %NULL for non-child tags
             * @param tagname name of tag
             */
            vfunc_custom_tag_start(
                builder: Gtk.Builder,
                child: GObject.Object | null,
                tagname: string,
            ): [boolean, Gtk.BuildableParser, any];
            /**
             * The getter corresponding to `set_id`. Implement this
             *   if you implement `set_id`.
             */
            vfunc_get_id(): string;
            /**
             * Retrieves the internal child called `childname` of the `buildable` object.
             * @param builder a `GtkBuilder`
             * @param childname name of child
             */
            vfunc_get_internal_child<T = GObject.Object>(builder: Gtk.Builder, childname: string): T;
            /**
             * Called when a builder finishes the parsing
             *  of a UI definition. It is normally not necessary to implement this,
             *  unless you need to perform special cleanup actions. `GtkWindow` sets
             *  the `GtkWidget:visible` property here.
             * @param builder
             */
            vfunc_parser_finished(builder: Gtk.Builder): void;
            /**
             * Sets a property of a buildable object.
             *  It is normally not necessary to implement this, g_object_set_property()
             *  is used by default. `GtkWindow` implements this to delay showing itself
             *  (i.e. setting the [property`Gtk`.Widget:visible] property) until the whole
             *  interface is created.
             * @param builder
             * @param name
             * @param value
             */
            vfunc_set_buildable_property(builder: Gtk.Builder, name: string, value: GObject.Value | any): void;
            /**
             * Stores the id attribute given in the `GtkBuilder` UI definition.
             *   `GtkWidget` stores the name as object data. Implement this method if your
             *   object has some notion of “ID” and it makes sense to map the XML id
             *   attribute to it.
             * @param id
             */
            vfunc_set_id(id: string): void;
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

        namespace Box {
            // Signal signatures
            interface SignalSignatures extends Gtk.Box.SignalSignatures {
                'notify::vertical': (pspec: GObject.ParamSpec) => void;
                'notify::children': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::baseline-child': (pspec: GObject.ParamSpec) => void;
                'notify::baseline-position': (pspec: GObject.ParamSpec) => void;
                'notify::homogeneous': (pspec: GObject.ParamSpec) => void;
                'notify::spacing': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::can-target': (pspec: GObject.ParamSpec) => void;
                'notify::css-classes': (pspec: GObject.ParamSpec) => void;
                'notify::css-name': (pspec: GObject.ParamSpec) => void;
                'notify::cursor': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::focusable': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::layout-manager': (pspec: GObject.ParamSpec) => void;
                'notify::limit-events': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::overflow': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::root': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
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

            static ['new'](): Box;

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
            get_child(): Gtk.Widget | null;
            set_child(value?: Gtk.Widget | null): void;
        }

        namespace Slider {
            // Signal signatures
            interface SignalSignatures extends Gtk.Scale.SignalSignatures {
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
                'notify::restrict-to-fill-level': (pspec: GObject.ParamSpec) => void;
                'notify::round-digits': (pspec: GObject.ParamSpec) => void;
                'notify::show-fill-level': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::can-target': (pspec: GObject.ParamSpec) => void;
                'notify::css-classes': (pspec: GObject.ParamSpec) => void;
                'notify::css-name': (pspec: GObject.ParamSpec) => void;
                'notify::cursor': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::focusable': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::layout-manager': (pspec: GObject.ParamSpec) => void;
                'notify::limit-events': (pspec: GObject.ParamSpec) => void;
                'notify::margin-bottom': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::margin-top': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::overflow': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::root': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Scale.ConstructorProps {
                value: number;
                min: number;
                max: number;
                step: number;
                page: number;
            }
        }

        class Slider extends Gtk.Scale {
            static $gtype: GObject.GType<Slider>;

            // Properties

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

        namespace Window {
            // Signal signatures
            interface SignalSignatures extends Gtk.Window.SignalSignatures {
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
                'notify::application': (pspec: GObject.ParamSpec) => void;
                'notify::child': (pspec: GObject.ParamSpec) => void;
                'notify::decorated': (pspec: GObject.ParamSpec) => void;
                'notify::default-height': (pspec: GObject.ParamSpec) => void;
                'notify::default-widget': (pspec: GObject.ParamSpec) => void;
                'notify::default-width': (pspec: GObject.ParamSpec) => void;
                'notify::deletable': (pspec: GObject.ParamSpec) => void;
                'notify::destroy-with-parent': (pspec: GObject.ParamSpec) => void;
                'notify::display': (pspec: GObject.ParamSpec) => void;
                'notify::focus-visible': (pspec: GObject.ParamSpec) => void;
                'notify::focus-widget': (pspec: GObject.ParamSpec) => void;
                'notify::fullscreened': (pspec: GObject.ParamSpec) => void;
                'notify::handle-menubar-accel': (pspec: GObject.ParamSpec) => void;
                'notify::hide-on-close': (pspec: GObject.ParamSpec) => void;
                'notify::icon-name': (pspec: GObject.ParamSpec) => void;
                'notify::is-active': (pspec: GObject.ParamSpec) => void;
                'notify::maximized': (pspec: GObject.ParamSpec) => void;
                'notify::mnemonics-visible': (pspec: GObject.ParamSpec) => void;
                'notify::modal': (pspec: GObject.ParamSpec) => void;
                'notify::resizable': (pspec: GObject.ParamSpec) => void;
                'notify::startup-id': (pspec: GObject.ParamSpec) => void;
                'notify::suspended': (pspec: GObject.ParamSpec) => void;
                'notify::title': (pspec: GObject.ParamSpec) => void;
                'notify::titlebar': (pspec: GObject.ParamSpec) => void;
                'notify::transient-for': (pspec: GObject.ParamSpec) => void;
                'notify::can-focus': (pspec: GObject.ParamSpec) => void;
                'notify::can-target': (pspec: GObject.ParamSpec) => void;
                'notify::css-classes': (pspec: GObject.ParamSpec) => void;
                'notify::css-name': (pspec: GObject.ParamSpec) => void;
                'notify::cursor': (pspec: GObject.ParamSpec) => void;
                'notify::focus-on-click': (pspec: GObject.ParamSpec) => void;
                'notify::focusable': (pspec: GObject.ParamSpec) => void;
                'notify::halign': (pspec: GObject.ParamSpec) => void;
                'notify::has-default': (pspec: GObject.ParamSpec) => void;
                'notify::has-focus': (pspec: GObject.ParamSpec) => void;
                'notify::has-tooltip': (pspec: GObject.ParamSpec) => void;
                'notify::height-request': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand': (pspec: GObject.ParamSpec) => void;
                'notify::hexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::layout-manager': (pspec: GObject.ParamSpec) => void;
                'notify::limit-events': (pspec: GObject.ParamSpec) => void;
                'notify::margin-end': (pspec: GObject.ParamSpec) => void;
                'notify::margin-start': (pspec: GObject.ParamSpec) => void;
                'notify::name': (pspec: GObject.ParamSpec) => void;
                'notify::opacity': (pspec: GObject.ParamSpec) => void;
                'notify::overflow': (pspec: GObject.ParamSpec) => void;
                'notify::parent': (pspec: GObject.ParamSpec) => void;
                'notify::receives-default': (pspec: GObject.ParamSpec) => void;
                'notify::root': (pspec: GObject.ParamSpec) => void;
                'notify::scale-factor': (pspec: GObject.ParamSpec) => void;
                'notify::sensitive': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-markup': (pspec: GObject.ParamSpec) => void;
                'notify::tooltip-text': (pspec: GObject.ParamSpec) => void;
                'notify::valign': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand': (pspec: GObject.ParamSpec) => void;
                'notify::vexpand-set': (pspec: GObject.ParamSpec) => void;
                'notify::visible': (pspec: GObject.ParamSpec) => void;
                'notify::width-request': (pspec: GObject.ParamSpec) => void;
            }

            // Constructor properties interface

            interface ConstructorProps extends Gtk.Window.ConstructorProps {
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
                'window-toggled': (arg0: Gtk.Window) => void;
                'notify::monitors': (pspec: GObject.ParamSpec) => void;
                'notify::windows': (pspec: GObject.ParamSpec) => void;
                'notify::gtk-theme': (pspec: GObject.ParamSpec) => void;
                'notify::icon-theme': (pspec: GObject.ParamSpec) => void;
                'notify::cursor-theme': (pspec: GObject.ParamSpec) => void;
                'notify::active-window': (pspec: GObject.ParamSpec) => void;
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
             * Shortcut for [method`Gtk`.IconTheme.add_search_path].
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

        type BinClass = typeof Bin;
        abstract class BinPrivate {
            static $gtype: GObject.GType<BinPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type BoxClass = typeof Box;
        abstract class BoxPrivate {
            static $gtype: GObject.GType<BoxPrivate>;

            // Constructors

            _init(...args: any[]): void;
        }

        type SliderClass = typeof Slider;
        abstract class SliderPrivate {
            static $gtype: GObject.GType<SliderPrivate>;

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
    import Astal40 from 'gi://Astal?version=4.0';
    export default Astal40;
}
// END
