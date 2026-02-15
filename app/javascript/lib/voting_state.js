export function shouldEnableSubmit(filledCount, maxSlots, totalAnswers) {
  return filledCount >= Math.min(maxSlots, totalAnswers)
}
