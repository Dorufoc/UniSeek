/**
 * 将各种格式的技能输入解析为干净的技能字符串数组
 *
 * 支持：
 * - null / undefined / 空字符串
 * - 字符串数组（过滤掉非字符串元素）
 * - JSON 数组字符串（如 '["Java","Vue"]'）
 * - 分隔文本（英文逗号、中文逗号、顿号、空白分隔）
 *
 * @param skills - 未知类型的技能输入
 * @returns 解析后的技能字符串数组
 */
export function parseSkills(skills: unknown): string[] {
  // 处理 null、undefined
  if (skills === null || skills === undefined) {
    return []
  }

  // 处理字符串数组
  if (Array.isArray(skills)) {
    return skills.filter((item): item is string => typeof item === 'string')
  }

  // 处理字符串
  if (typeof skills === 'string') {
    const trimmed = skills.trim()
    // 空字符串返回空数组
    if (trimmed === '') {
      return []
    }

    // 先尝试 JSON 解析
    try {
      const parsed = JSON.parse(trimmed)
      if (Array.isArray(parsed)) {
        return parsed.filter((item): item is string => typeof item === 'string')
      }
      // JSON 解析成功但不是数组，按分隔文本处理
    } catch {
      // JSON 解析失败，继续按分隔文本分割
    }

    // 按分隔符分割：英文逗号、中文逗号、顿号、空白
    const parts = trimmed.split(/[,，、\s]+/)
    return parts.map(part => part.trim()).filter(part => part !== '')
  }

  // 其他类型（number、object 等）返回空数组
  return []
}
