export class RegionPathNode {
  id: number
  name: string
  children: RegionPathNode[]

  constructor(id: number, name: string, children: RegionPathNode[]) {
    this.id = id
    this.name = name
    this.children = children
  }
}

/**
 * 地区路径节点，用于回溯时记录从根到目标节点的路径。
 */
interface PathNode {
  id: number
  name: string
}

/**
 * 地区完整路径构建工具。
 * 根据地区 ID 从地区树中回溯父节点，生成省市区完整路径；
 * 直辖市出现相邻重复名称时自动折叠，如“北京市北京市朝阳区”显示为“北京市朝阳区”。
 */
export class RegionPathBuilder {
  /**
   * 按地区 ID 生成完整路径。
   * @param regionTree 地区树根节点数组
   * @param regionId 目标地区 ID
   * @returns 完整路径字符串；未找到或 ID 不合法时返回空字符串
   */
  static buildPathById(regionTree: RegionPathNode[], regionId: number | null | undefined): string {
    if (regionId === null || regionId === undefined || regionId <= 0) {
      return ''
    }
    if (regionTree.length === 0) {
      return ''
    }
    const path: PathNode[] = []
    const found: boolean = RegionPathBuilder.findPath(regionTree, regionId, path)
    if (!found) {
      return ''
    }
    return RegionPathBuilder.collapsePath(path)
  }

  /**
   * 深度优先搜索目标节点，并用 path 收集从根到目标节点的路径。
   */
  private static findPath(nodes: RegionPathNode[], regionId: number, path: PathNode[]): boolean {
    for (let i = 0; i < nodes.length; i++) {
      const node: RegionPathNode = nodes[i]
      path.push({ id: node.id, name: node.name })
      if (node.id === regionId) {
        return true
      }
      if (node.children && node.children.length > 0) {
        const foundInChildren: boolean = RegionPathBuilder.findPath(node.children, regionId, path)
        if (foundInChildren) {
          return true
        }
      }
      path.pop()
    }
    return false
  }

  /**
   * 折叠路径中相邻的重复名称，再拼接为完整字符串。
   */
  private static collapsePath(path: PathNode[]): string {
    if (path.length === 0) {
      return ''
    }
    let result: string = path[0].name
    for (let i = 1; i < path.length; i++) {
      if (path[i].name !== path[i - 1].name) {
        result = result + path[i].name
      }
    }
    return result
  }
}
