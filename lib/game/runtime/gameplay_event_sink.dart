import '../domain/gameplay_event.dart';

typedef GameplayEventSink = void Function(GameplayEvent event);

void ignoreGameplayEvent(GameplayEvent event) {}
