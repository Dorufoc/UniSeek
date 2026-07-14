package com.uniseek.util;

import org.springframework.util.DigestUtils;

import java.security.SecureRandom;

/**
 * 密码工具类 —— MD5 + 随机盐加密
 */
public class PasswordUtil {

    private static final int SALT_LENGTH = 16;

    /**
     * 生成随机盐（32 位十六进制字符串）
     *
     * @return 盐值
     */
    public static String generateSalt() {
        SecureRandom random = new SecureRandom();
        byte[] bytes = new byte[SALT_LENGTH];
        random.nextBytes(bytes);
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b & 0xff));
        }
        return sb.toString();
    }

    /**
     * 加密密码：MD5(password + salt)
     *
     * @param password 明文密码
     * @param salt     盐值
     * @return 加密后的密码（十六进制字符串）
     */
    public static String encryptPassword(String password, String salt) {
        String input = password + salt;
        return DigestUtils.md5DigestAsHex(input.getBytes());
    }

    /**
     * 验证密码
     *
     * @param inputPassword  用户输入的明文密码
     * @param storedPassword 数据库中存储的加密密码
     * @param salt           盐值
     * @return true 匹配，false 不匹配
     */
    public static boolean verify(String inputPassword, String storedPassword, String salt) {
        return storedPassword.equals(encryptPassword(inputPassword, salt));
    }
}
