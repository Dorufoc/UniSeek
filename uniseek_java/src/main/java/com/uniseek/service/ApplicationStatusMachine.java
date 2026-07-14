package com.uniseek.service;

import com.uniseek.common.exception.BusinessException;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * 投递状态机 —— 校验状态流转合法性
 * <p>
 * 状态定义：
 * 0 已投递 / 1 待面试 / 2 待定 / 3 已录用 / 4 已淘汰 / 5 已完成
 * </p>
 */
@Component
public class ApplicationStatusMachine {

    /** 有效状态流转映射表 */
    private static final Map<Integer, List<Integer>> VALID_TRANSITIONS = new HashMap<>();

    static {
        // 0 已投递 -> 1 待面试, 2 待定, 4 已淘汰
        VALID_TRANSITIONS.put(0, Arrays.asList(1, 2, 4));
        // 1 待面试 -> 2 待定, 3 已录用, 4 已淘汰
        VALID_TRANSITIONS.put(1, Arrays.asList(2, 3, 4));
        // 2 待定 -> 1 待面试(重新安排), 3 已录用, 4 已淘汰
        VALID_TRANSITIONS.put(2, Arrays.asList(1, 3, 4));
        // 3 已录用 -> 5 已完成
        VALID_TRANSITIONS.put(3, Collections.singletonList(5));
        // 4 已淘汰 -> 终态
        VALID_TRANSITIONS.put(4, Collections.emptyList());
        // 5 已完成 -> 终态
        VALID_TRANSITIONS.put(5, Collections.emptyList());
    }

    /**
     * 校验状态流转是否合法
     *
     * @param fromStatus 当前状态
     * @param toStatus   目标状态
     * @throws BusinessException 如果流转不合法
     */
    public void validateTransition(Integer fromStatus, Integer toStatus) {
        List<Integer> allowedTargets = VALID_TRANSITIONS.get(fromStatus);
        if (allowedTargets == null) {
            throw new BusinessException("非法状态值: " + fromStatus);
        }
        if (!allowedTargets.contains(toStatus)) {
            throw new BusinessException(
                    String.format("状态流转非法：无法从「%s」流转到「%s」",
                            getStatusDesc(fromStatus), getStatusDesc(toStatus)));
        }
    }

    /**
     * 判断是否为终态
     *
     * @param status 状态值
     * @return true 如果状态为 4（已淘汰）或 5（已完成）
     */
    public boolean isFinalState(Integer status) {
        return status == 4 || status == 5;
    }

    /**
     * 获取状态中文描述
     */
    private String getStatusDesc(Integer status) {
        switch (status) {
            case 0:  return "已投递";
            case 1:  return "待面试";
            case 2:  return "待定";
            case 3:  return "已录用";
            case 4:  return "已淘汰";
            case 5:  return "已完成";
            default: return "未知状态(" + status + ")";
        }
    }
}
