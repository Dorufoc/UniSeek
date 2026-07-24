import { ApiClient } from './ApiClient';

// 原始树形接口（API 返回格式）
export interface RegionNode {
  id: number
  name: string
  level: number
  children: RegionNode[]
}

export interface CategoryNode {
  id: number
  parentId: number | null
  name: string
  sortOrder: number
  children: CategoryNode[]
}

// UI 扁平接口（Picker 组件使用）
export interface Province {
  name: string
  isMunicipality: boolean
  cities: City[]
}

export interface City {
  name: string
  districts: District[]
}

export interface District {
  name: string
}

export interface Field {
  name: string
  occupations: Occupation[]
}

export interface Occupation {
  name: string
}

interface TreeNode<T> {
  id: number
  name: string
  children?: T[]
}

export class DataService {
  private static regionTree: RegionNode[] | null = null
  private static categoryTree: CategoryNode[] | null = null
  private static provincesCache: Province[] | null = null
  private static fieldsCache: Field[] | null = null

  static async getRegionTree(): Promise<RegionNode[]> {
    if (DataService.regionTree) {
      return DataService.regionTree
    }
    try {
      DataService.regionTree = await ApiClient.get<RegionNode[]>('/api/region/tree')
      DataService.provincesCache = DataService.toProvinces(DataService.regionTree)
      return DataService.regionTree
    } catch {
      DataService.regionTree = DataService.getFallbackRegions()
      DataService.provincesCache = DataService.toProvinces(DataService.regionTree)
      return DataService.regionTree
    }
  }

  static async getCategoryTree(): Promise<CategoryNode[]> {
    if (DataService.categoryTree) {
      return DataService.categoryTree
    }
    try {
      DataService.categoryTree = await ApiClient.get<CategoryNode[]>('/api/categories')
      DataService.fieldsCache = DataService.toFields(DataService.categoryTree)
      return DataService.categoryTree
    } catch {
      DataService.categoryTree = DataService.getFallbackCategories()
      DataService.fieldsCache = DataService.toFields(DataService.categoryTree)
      return DataService.categoryTree
    }
  }

  static getProvinces(): Province[] {
    if (DataService.provincesCache) {
      return DataService.provincesCache
    }
    if (DataService.regionTree) {
      DataService.provincesCache = DataService.toProvinces(DataService.regionTree)
      return DataService.provincesCache
    }
    DataService.regionTree = DataService.getFallbackRegions()
    DataService.provincesCache = DataService.toProvinces(DataService.regionTree)
    DataService.getRegionTree()
    return DataService.provincesCache
  }

  static getProvinceByName(name: string): Province | null {
    if (!DataService.regionTree && !DataService.provincesCache) {
      DataService.getProvinces()
    }
    if (DataService.provincesCache) {
      for (const p of DataService.provincesCache) {
        if (p.name === name) return p
      }
    }
    return null
  }

  static async getProvinceChildren(parentId: number): Promise<RegionNode[]> {
    try {
      return ApiClient.get<RegionNode[]>('/api/region/children/' + parentId)
    } catch {
      const tree = await DataService.getRegionTree()
      return DataService.findChildren(tree, parentId)
    }
  }

  static getFields(): Field[] {
    if (DataService.fieldsCache) {
      return DataService.fieldsCache
    }
    if (DataService.categoryTree) {
      DataService.fieldsCache = DataService.toFields(DataService.categoryTree)
      return DataService.fieldsCache
    }
    DataService.categoryTree = DataService.getFallbackCategories()
    DataService.fieldsCache = DataService.toFields(DataService.categoryTree)
    DataService.getCategoryTree()
    return DataService.fieldsCache
  }

  static getFieldByName(name: string): Field | null {
    if (!DataService.categoryTree && !DataService.fieldsCache) {
      DataService.getFields()
    }
    if (DataService.fieldsCache) {
      for (const f of DataService.fieldsCache) {
        if (f.name === name) return f
      }
    }
    return null
  }

  static async getFieldChildren(parentId: number): Promise<CategoryNode[]> {
    const tree = await DataService.getCategoryTree()
    return DataService.findChildren(tree, parentId)
  }

  private static toProvinces(nodes: RegionNode[]): Province[] {
    const result: Province[] = []
    for (const n of nodes) {
      const cities: City[] = []
      if (n.children) {
        for (const c of n.children) {
          const districts: District[] = []
          if (c.children) {
            for (const d of c.children) {
              districts.push({ name: d.name })
            }
          }
          cities.push({ name: c.name, districts })
        }
      }
      result.push({
        name: n.name,
        isMunicipality: n.children?.length === 1,
        cities
      })
    }
    return result
  }

  private static toFields(nodes: CategoryNode[]): Field[] {
    const result: Field[] = []
    for (const n of nodes) {
      const occupations: Occupation[] = []
      if (n.children) {
        for (const c of n.children) {
          occupations.push({ name: c.name })
        }
      }
      result.push({ name: n.name, occupations })
    }
    return result
  }

  private static findChildren<T extends TreeNode<T>>(nodes: T[], parentId: number): T[] {
    for (const node of nodes) {
      if (node.id === parentId) {
        if (node.children) {
          return node.children
        }
        return []
      }
      if (node.children) {
        const found = DataService.findChildren(node.children, parentId)
        if (found.length > 0) return found
      }
    }
    return []
  }

  private static findByName<T extends TreeNode<T>>(nodes: T[], name: string): T | null {
    for (const node of nodes) {
      if (node.name === name) return node
      if (node.children) {
        const found = DataService.findByName(node.children, name)
        if (found) return found
      }
    }
    return null
  }

  // ==================== 名称到ID的查找方法 ====================

  /**
   * 根据完整名称查找地区ID。
   * 支持格式： "北京"（单级）、"广东-广州"（两级）、"北京-朝阳区"（直辖市两级）
   */
  static getRegionIdByName(fullName: string): number | null {
    if (!DataService.regionTree) {
      return null
    }
    const names = fullName.split('-')
    // 先尝试精确路径查找
    let result = DataService.findRegionIdByPath(DataService.regionTree, names, 0)
    // 如果没找到且是单级名称，则递归搜索整棵树（处理城市不带省份前缀的情况）
    if (result === null && names.length === 1) {
      result = DataService.deepFindRegionId(DataService.regionTree, names[0])
    }
    return result
  }

  /**
   * 根据完整名称查找分类ID。
   * 支持格式： "设计创作"（单级）、"设计创作-UI设计"（两级）
   */
  static getCategoryIdByName(fullName: string): number | null {
    if (!DataService.categoryTree) {
      return null
    }
    const names = fullName.split('-')
    let result = DataService.findCategoryIdByPath(DataService.categoryTree, names, 0)
    if (result === null && names.length === 1) {
      result = DataService.deepFindCategoryId(DataService.categoryTree, names[0])
    }
    return result
  }

  // 按路径逐级查找地区（从根开始匹配）
  private static findRegionIdByPath(nodes: RegionNode[], names: string[], depth: number): number | null {
    for (const n of nodes) {
      if (n.name === names[depth]) {
        if (depth === names.length - 1) {
          return n.id
        }
        if (n.children) {
          const found = DataService.findRegionIdByPath(n.children, names, depth + 1)
          if (found !== null) {
            return found
          }
        }
      }
    }
    return null
  }

  // 按路径逐级查找分类（从根开始匹配）
  private static findCategoryIdByPath(nodes: CategoryNode[], names: string[], depth: number): number | null {
    for (const n of nodes) {
      if (n.name === names[depth]) {
        if (depth === names.length - 1) {
          return n.id
        }
        if (n.children) {
          const found = DataService.findCategoryIdByPath(n.children, names, depth + 1)
          if (found !== null) {
            return found
          }
        }
      }
    }
    return null
  }

  // 递归深搜地区ID（单级名称，可能在树的任意层级）
  private static deepFindRegionId(nodes: RegionNode[], name: string): number | null {
    for (const n of nodes) {
      if (n.name === name) {
        return n.id
      }
      if (n.children) {
        const found = DataService.deepFindRegionId(n.children, name)
        if (found !== null) {
          return found
        }
      }
    }
    return null
  }

  // 递归深搜分类ID（单级名称，可能在树的任意层级）
  private static deepFindCategoryId(nodes: CategoryNode[], name: string): number | null {
    for (const n of nodes) {
      if (n.name === name) {
        return n.id
      }
      if (n.children) {
        const found = DataService.deepFindCategoryId(n.children, name)
        if (found !== null) {
          return found
        }
      }
    }
    return null
  }

  // ==================== ID/名称到完整路径的查找方法 ====================

  /**
   * 根据区县名称反查完整省市区县路径。
   * 例如 "西湖区" → "浙江省杭州市西湖区"。
   * 如果未查到则返回 null，调用方应降级显示原始名称。
   */
  static getRegionFullPath(regionName: string): string | null {
    if (!DataService.provincesCache) {
      DataService.getProvinces()
      if (!DataService.provincesCache) return null
    }

    for (const province of DataService.provincesCache) {
      if (province.isMunicipality) {
        // 直辖市：省=市，跳过市层级直接查区
        const city = province.cities[0]
        if (city.name === regionName) return province.name
        for (const district of city.districts) {
          if (district.name === regionName) {
            return province.name + city.name + district.name
          }
        }
      } else {
        // 非直辖市：省→市→区三级
        for (const city of province.cities) {
          if (city.name === regionName) return province.name + city.name
          for (const district of city.districts) {
            if (district.name === regionName) {
              return province.name + city.name + district.name
            }
          }
        }
      }
      if (province.name === regionName) return province.name
    }

    return null
  }

  /**
   * 根据地区 ID 反查地区名称。
   * 支持省/市/区县任意层级 ID。
   */
  static async getRegionNameById(regionId: number | null | undefined): Promise<string | null> {
    if (regionId == null) {
      return null
    }
    if (!DataService.regionTree) {
      await DataService.getRegionTree()
    }
    return DataService.findRegionNameById(DataService.regionTree || [], regionId)
  }

  private static findRegionNameById(nodes: RegionNode[], regionId: number): string | null {
    for (const node of nodes) {
      if (node.id === regionId) {
        return node.name
      }
      if (node.children) {
        const found = DataService.findRegionNameById(node.children, regionId)
        if (found !== null) {
          return found
        }
      }
    }
    return null
  }

  private static getFallbackRegions(): RegionNode[] {
    return [
      { id: 110000, name: '北京市', level: 1, children: [
        { id: 110100, name: '北京市', level: 2, children: [
          { id: 110101, name: '东城区', level: 3, children: [] },
          { id: 110102, name: '西城区', level: 3, children: [] },
          { id: 110105, name: '朝阳区', level: 3, children: [] },
          { id: 110106, name: '丰台区', level: 3, children: [] },
          { id: 110107, name: '石景山区', level: 3, children: [] },
          { id: 110108, name: '海淀区', level: 3, children: [] }
        ]}
      ]},
      { id: 310000, name: '上海市', level: 1, children: [
        { id: 310100, name: '上海市', level: 2, children: [
          { id: 310101, name: '黄浦区', level: 3, children: [] },
          { id: 310104, name: '徐汇区', level: 3, children: [] },
          { id: 310105, name: '长宁区', level: 3, children: [] },
          { id: 310106, name: '静安区', level: 3, children: [] },
          { id: 310115, name: '浦东新区', level: 3, children: [] }
        ]}
      ]},
      { id: 440000, name: '广东省', level: 1, children: [
        { id: 440100, name: '广州市', level: 2, children: [
          { id: 440103, name: '荔湾区', level: 3, children: [] },
          { id: 440104, name: '越秀区', level: 3, children: [] },
          { id: 440105, name: '海珠区', level: 3, children: [] },
          { id: 440106, name: '天河区', level: 3, children: [] }
        ]},
        { id: 440300, name: '深圳市', level: 2, children: [
          { id: 440303, name: '罗湖区', level: 3, children: [] },
          { id: 440304, name: '福田区', level: 3, children: [] },
          { id: 440305, name: '南山区', level: 3, children: [] }
        ]}
      ]},
      { id: 330000, name: '浙江省', level: 1, children: [
        { id: 330100, name: '杭州市', level: 2, children: [
          { id: 330102, name: '上城区', level: 3, children: [] },
          { id: 330103, name: '下城区', level: 3, children: [] },
          { id: 330106, name: '西湖区', level: 3, children: [] },
          { id: 330108, name: '滨江区', level: 3, children: [] }
        ]}
      ]}
    ]
  }

  private static getFallbackCategories(): CategoryNode[] {
    return [
      { id: 1, parentId: null, name: '餐饮服务', sortOrder: 1, children: [
        { id: 16, parentId: 1, name: '服务员', sortOrder: 1, children: [] },
        { id: 17, parentId: 1, name: '后厨帮工', sortOrder: 2, children: [] },
        { id: 18, parentId: 1, name: '送餐员', sortOrder: 3, children: [] }
      ]},
      { id: 2, parentId: null, name: '家教辅导', sortOrder: 2, children: [
        { id: 21, parentId: 2, name: '小学陪读', sortOrder: 1, children: [] },
        { id: 22, parentId: 2, name: '初高中辅导', sortOrder: 2, children: [] }
      ]},
      { id: 6, parentId: null, name: '设计创作', sortOrder: 6, children: [
        { id: 28, parentId: 6, name: '平面设计', sortOrder: 1, children: [] },
        { id: 29, parentId: 6, name: 'UI设计', sortOrder: 2, children: [] },
        { id: 30, parentId: 6, name: '视频剪辑', sortOrder: 3, children: [] }
      ]},
      { id: 8, parentId: null, name: '技术支持', sortOrder: 8, children: [
        { id: 40, parentId: 8, name: 'IT运维', sortOrder: 1, children: [] },
        { id: 41, parentId: 8, name: '软件测试', sortOrder: 2, children: [] },
        { id: 42, parentId: 8, name: '技术助理', sortOrder: 3, children: [] }
      ]}
    ]
  }
}
