package com.uniseek.auth.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 实名认证信息 VO（脱敏后返回给前端）
 */
@Data
public class RealNameAuthVO {

    /** 真实姓名 */
    private String realName;

    /** 身份证号（脱敏格式：110101********1234） */
    private String idCard;

    /** 认证时间 */
    private LocalDateTime authTime;

    /**
     * 身份证号脱敏：保留前 6 位和最后 4 位，中间用 ******** 代替
     *
     * @param idCard 原始身份证号
     * @return 脱敏后的身份证号，如 110101********1234
     */
    public static String idCardDesensitization(String idCard) {
        if (idCard == null || idCard.length() < 10) {
            return idCard;
        }
        return idCard.substring(0, 6) + "********" + idCard.substring(idCard.length() - 4);
    }
}
