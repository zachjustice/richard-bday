export function shouldDedupeNavigate(url, lastUrl, lastAt, now, thresholdMs) {
  return url === lastUrl && now - lastAt < thresholdMs
}
