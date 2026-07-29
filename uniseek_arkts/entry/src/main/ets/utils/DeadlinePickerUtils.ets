export function applyDatePickerResult(selected: Date, value: DatePickerResult): Date {
  const year: number = value.year === undefined ? selected.getFullYear() : value.year
  const month: number = value.month === undefined ? selected.getMonth() : value.month
  const day: number = value.day === undefined ? selected.getDate() : value.day
  return new Date(year, month, day, selected.getHours(), selected.getMinutes())
}

export function applyTimePickerResult(selected: Date, value: TimePickerResult): Date {
  const hour: number = value.hour === undefined ? selected.getHours() : value.hour
  const minute: number = value.minute === undefined ? selected.getMinutes() : value.minute
  return new Date(selected.getFullYear(), selected.getMonth(), selected.getDate(), hour, minute)
}
