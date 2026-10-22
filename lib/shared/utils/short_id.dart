/// `09150348…99b5`: the head and the tail of [id], cut in the middle
/// (DS-CMP-22).
///
/// The tail is what people compare when verifying an id, so an id is never
/// truncated at its end. Ids too short to gain anything are returned whole.
String shortOrderId(String id, {int head = 8, int tail = 4}) {
  if (id.length <= head + tail + 1) return id;
  return '${id.substring(0, head)}…${id.substring(id.length - tail)}';
}
