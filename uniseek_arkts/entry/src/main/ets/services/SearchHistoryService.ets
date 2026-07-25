// SearchHistoryService.ets — 搜索历史本地持久化服务
// 职责：基于鸿蒙 preferences 按搜索模式（职位/公司）分别维护搜索历史；所有数据仅保存在本地，不上传服务端。

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'uniseek_search_history';
const PREF_KEY_JOB = 'job_keywords';
const PREF_KEY_COMPANY = 'company_keywords';
const MAX_HISTORY = 20;

export enum SearchMode {
  JOB = 0,
  COMPANY = 1
}

export class SearchHistoryService {
  /**
   * 热搜关键词（本地静态池，运营后台可后续替换为接口下发）。
   */
  static getHotKeywords(): string[] {
    return ['客服', '家教', '打包分拣', '新媒体运营', '日结', '兼职会计', '骑手', '促销导购', '网店客服', '展会协助'];
  }

  /**
   * 加载指定搜索模式下的本地历史。
   * @param context UIAbilityContext
   * @param mode 搜索模式
   */
  static async load(context: common.UIAbilityContext, mode: SearchMode): Promise<string[]> {
    try {
      const pref = await preferences.getPreferences(context, { name: PREF_NAME });
      const raw = pref.getSync(SearchHistoryService.prefKeyOf(mode), '[]') as string;
      const list = JSON.parse(raw) as string[];
      if (!Array.isArray(list)) {
        return [];
      }
      return list
        .map((item: string) => item.trim())
        .filter((item: string) => item.length > 0);
    } catch (e) {
      console.error('[SearchHistoryService] 加载搜索历史失败: ' + (e as Error).message);
      return [];
    }
  }

  /**
   * 保存指定搜索模式下的历史。
   * @param context UIAbilityContext
   * @param mode 搜索模式
   * @param history 搜索关键词数组
   */
  static async save(context: common.UIAbilityContext, mode: SearchMode, history: string[]): Promise<void> {
    try {
      const cleaned = SearchHistoryService.cleanHistory(history);
      const pref = await preferences.getPreferences(context, { name: PREF_NAME });
      pref.putSync(SearchHistoryService.prefKeyOf(mode), JSON.stringify(cleaned));
      await pref.flush();
    } catch (e) {
      console.error('[SearchHistoryService] 保存搜索历史失败: ' + (e as Error).message);
    }
  }

  /**
   * 添加一条搜索关键词。如果已存在则移到队首，超出上限则淘汰最旧记录。
   * @param context UIAbilityContext
   * @param mode 搜索模式
   * @param keyword 关键词
   */
  static async add(context: common.UIAbilityContext, mode: SearchMode, keyword: string): Promise<string[]> {
    const trimmed = keyword.trim();
    if (trimmed.length === 0) {
      return SearchHistoryService.load(context, mode);
    }
    const history = await SearchHistoryService.load(context, mode);
    const filtered = history.filter((item: string) => item !== trimmed);
    filtered.unshift(trimmed);
    const result = filtered.slice(0, MAX_HISTORY);
    await SearchHistoryService.save(context, mode, result);
    return result;
  }

  /**
   * 删除单条搜索历史。
   * @param context UIAbilityContext
   * @param mode 搜索模式
   * @param keyword 要删除的关键词
   */
  static async remove(context: common.UIAbilityContext, mode: SearchMode, keyword: string): Promise<string[]> {
    const history = await SearchHistoryService.load(context, mode);
    const result = history.filter((item: string) => item !== keyword);
    await SearchHistoryService.save(context, mode, result);
    return result;
  }

  /**
   * 清空指定模式下的全部搜索历史。
   * @param context UIAbilityContext
   * @param mode 搜索模式
   */
  static async clear(context: common.UIAbilityContext, mode: SearchMode): Promise<void> {
    await SearchHistoryService.save(context, mode, []);
  }

  private static prefKeyOf(mode: SearchMode): string {
    return mode === SearchMode.COMPANY ? PREF_KEY_COMPANY : PREF_KEY_JOB;
  }

  private static cleanHistory(history: string[]): string[] {
    const trimmed = history.map((item: string) => item.trim());
    const deduped: string[] = [];
    for (const item of trimmed) {
      if (item.length > 0 && deduped.indexOf(item) < 0) {
        deduped.push(item);
      }
    }
    return deduped.slice(0, MAX_HISTORY);
  }
}

