import 'dart:developer';

/// Filter key for [TimelineTask]s that this library records.
///
/// Asynchronous tasks that are recorded by this library will be displayed in
/// their own lane, with this value as its name.
const timelineTaskFilterKey = 'VectorTileRenderer';

/// Prefix for [Timeline] events that this library records.
///
/// By searching for this value in the DevTools Performance page, you can find
/// all the [Timeline] events recorded by this library.
const timelinePrefix = 'VTR';
