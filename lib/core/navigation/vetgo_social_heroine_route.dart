import 'package:flutter/material.dart';
import 'package:heroine/heroine.dart';

/// Ruta modal como [MaterialPageRoute] pero compatible con [HeroinePageRouteMixin]
/// (no opaca; permite gestos dismiss asociados a [Heroine]).
class VetgoSocialHeroineRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T>, HeroinePageRouteMixin<T> {
  VetgoSocialHeroineRoute({
    required this.builder,
    super.settings,
    super.requestFocus,
    this.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
    super.barrierDismissible = false,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  });

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
