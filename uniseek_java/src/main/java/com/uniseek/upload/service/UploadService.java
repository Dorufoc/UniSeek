package com.uniseek.upload.service;

import com.uniseek.common.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * 文件上传服务
 */
@Service
public class UploadService {

    private static final Logger log = LoggerFactory.getLogger(UploadService.class);

    /** 允许的图片扩展名 */
    private static final Set<String> IMAGE_EXTENSIONS = new HashSet<>(
            Arrays.asList("jpg", "jpeg", "png", "webp"));

    /** 允许的文件扩展名 */
    private static final Set<String> FILE_EXTENSIONS = new HashSet<>(
            Arrays.asList("pdf", "doc", "docx"));

    /** 图片最大 5MB */
    private static final long IMAGE_MAX_SIZE = 5 * 1024 * 1024L;

    /** 文件最大 10MB */
    private static final long FILE_MAX_SIZE = 10 * 1024 * 1024L;

    @Value("${upload.path:./upload}")
    private String uploadBasePath;

    private Path basePath;

    @PostConstruct
    public void init() {
        this.basePath = Paths.get(uploadBasePath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.basePath);
            log.info("文件上传根目录已初始化: {}", this.basePath);
        } catch (IOException e) {
            throw new RuntimeException("无法创建上传根目录: " + this.basePath, e);
        }
    }

    /**
     * 上传图片文件
     *
     * @param file 图片文件（支持 jpg/png/webp，最大 5MB）
     * @return 可访问的图片 URL
     */
    public String uploadImage(MultipartFile file) {
        // 校验文件非空
        if (file == null || file.isEmpty()) {
            throw new BusinessException("上传文件不能为空");
        }

        // 校验文件扩展名
        String originalFilename = file.getOriginalFilename();
        String extension = getExtension(originalFilename);
        if (!IMAGE_EXTENSIONS.contains(extension)) {
            throw new BusinessException("不支持的图片格式，仅支持 jpg/png/webp");
        }

        // 校验文件大小
        if (file.getSize() > IMAGE_MAX_SIZE) {
            throw new BusinessException("图片大小不能超过 5MB");
        }

        // 保存文件并返回 URL
        String relativePath = saveFile(file, "images", extension);
        return "/api/files/" + relativePath;
    }

    /**
     * 上传通用文件
     *
     * @param file 通用文件（支持 pdf/doc/docx，最大 10MB）
     * @return 可访问的文件 URL
     */
    public String uploadFile(MultipartFile file) {
        // 校验文件非空
        if (file == null || file.isEmpty()) {
            throw new BusinessException("上传文件不能为空");
        }

        // 校验文件扩展名
        String originalFilename = file.getOriginalFilename();
        String extension = getExtension(originalFilename);
        if (!FILE_EXTENSIONS.contains(extension)) {
            throw new BusinessException("不支持的文件格式，仅支持 pdf/doc/docx");
        }

        // 校验文件大小
        if (file.getSize() > FILE_MAX_SIZE) {
            throw new BusinessException("文件大小不能超过 10MB");
        }

        // 保存文件并返回 URL
        String relativePath = saveFile(file, "files", extension);
        return "/api/files/" + relativePath;
    }

    /**
     * 保存文件到磁盘
     *
     * @param file     上传的文件
     * @param category 分类目录（images / files）
     * @param extension 文件扩展名
     * @return 相对于上传根目录的路径（使用正斜杠）
     */
    private String saveFile(MultipartFile file, String category, String extension) {
        // 按日期组织目录：category/YYYYMMDD/
        String dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String filename = UUID.randomUUID().toString().replace("-", "") + "." + extension;
        String relativePath = category + "/" + dateStr + "/" + filename;

        Path targetPath = basePath.resolve(relativePath).normalize();

        // 确保目标目录存在
        try {
            Files.createDirectories(targetPath.getParent());
        } catch (IOException e) {
            log.error("无法创建上传子目录: {}", targetPath.getParent(), e);
            throw new BusinessException("文件保存失败，无法创建目录");
        }

        // 写入文件
        try {
            file.transferTo(targetPath.toFile());
            log.info("文件上传成功: {}（大小: {} bytes）", relativePath, file.getSize());
        } catch (IOException e) {
            log.error("文件写入失败: {}", relativePath, e);
            throw new BusinessException("文件保存失败");
        }

        // 统一返回正斜杠路径
        return relativePath.replace("\\", "/");
    }

    /**
     * 从文件名中提取小写扩展名
     */
    private String getExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return "";
        }
        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex == -1) {
            return "";
        }
        return filename.substring(dotIndex + 1).toLowerCase();
    }
}
