/** 手机窗口断点，与 HarmonyOS 紧凑、适中、展开三种布局对应。 */
export enum WindowBreakpoint {
  COMPACT = 0,
  MEDIUM = 1,
  EXPANDED = 2
}

/** 统一维护窗口宽度到布局断点的映射。 */
export class BreakpointResolver {
  static resolve(width: number): WindowBreakpoint {
    if (width >= 840) {
      return WindowBreakpoint.EXPANDED
    }
    if (width >= 600) {
      return WindowBreakpoint.MEDIUM
    }
    return WindowBreakpoint.COMPACT
  }
}
