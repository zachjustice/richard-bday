export function timerPhase(timeRemaining, duration) {
  const progress = timeRemaining / duration
  if (timeRemaining <= 0) return "zero"
  if (progress > 0.5) return "green"
  if (progress > 0.25) return "orange"
  return "red"
}
