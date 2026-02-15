export function findInsertionIndex(itemId, existingIds, initialOrder) {
  const targetIndex = initialOrder.indexOf(itemId)
  for (let i = 0; i < existingIds.length; i++) {
    if (initialOrder.indexOf(existingIds[i]) > targetIndex) return i
  }
  return existingIds.length
}
