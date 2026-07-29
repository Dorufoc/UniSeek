import { RegionPathBuilder, RegionPathNode } from './RegionPathBuilder'

/**
 * 地区兜底选项，用于构建完整路径失败时降级显示已选中的地区标签。
 */
export interface RegionFallbackOption {
  id: number
  label: string
}

/**
 * 解析企业资质页面应显示的地区名称。
 * 优先根据地区树构建完整省市区路径；解析失败且提供兜底选项时，返回选项中的标签。
 *
 * @param regionId 目标地区 ID
 * @param regionTree 已加载的地区树
 * @param fallbackOptions 扁平化的地区选择项（如 SelectorSheet 的数据源）
 * @returns 展示用地区名称；无法解析时返回空字符串
 */
export function resolveEnterpriseRegionName(
  regionId: number | null | undefined,
  regionTree: RegionPathNode[],
  fallbackOptions?: RegionFallbackOption[]
): string {
  const fullPath: string = RegionPathBuilder.buildPathById(regionTree, regionId)
  if (fullPath.length > 0) {
    return fullPath
  }

  if (fallbackOptions) {
    for (const option of fallbackOptions) {
      if (option.id === regionId) {
        return option.label
      }
    }
  }

  return ''
}
