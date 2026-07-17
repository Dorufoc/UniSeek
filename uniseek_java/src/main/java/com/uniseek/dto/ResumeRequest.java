package com.uniseek.dto;

import java.time.LocalDate;

/**
 * 简历请求 DTO
 * 注意：不包含 realName 字段，realName 从 real_name_auth 表 JOIN 获取
 */
public class ResumeRequest {

    /** 性别：0 女 / 1 男 */
    private Integer gender;

    /** 出生日期 */
    private LocalDate birthDate;

    /** 最高学历 */
    private String education;

    /** 毕业院校 */
    private String school;

    /** 毕业时间 */
    private LocalDate graduationDate;

    /** 技能特长 */
    private String skills;

    /** 工作经历 */
    private String experience;

    /** 附件简历 URL */
    private String attachmentUrl;

    public Integer getGender() {
        return gender;
    }

    public void setGender(Integer gender) {
        this.gender = gender;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(LocalDate birthDate) {
        this.birthDate = birthDate;
    }

    public String getEducation() {
        return education;
    }

    public void setEducation(String education) {
        this.education = education;
    }

    public String getSchool() {
        return school;
    }

    public void setSchool(String school) {
        this.school = school;
    }

    public LocalDate getGraduationDate() {
        return graduationDate;
    }

    public void setGraduationDate(LocalDate graduationDate) {
        this.graduationDate = graduationDate;
    }

    public String getSkills() {
        return skills;
    }

    public void setSkills(String skills) {
        this.skills = skills;
    }

    public String getExperience() {
        return experience;
    }

    public void setExperience(String experience) {
        this.experience = experience;
    }

    public String getAttachmentUrl() {
        return attachmentUrl;
    }

    public void setAttachmentUrl(String attachmentUrl) {
        this.attachmentUrl = attachmentUrl;
    }
}
