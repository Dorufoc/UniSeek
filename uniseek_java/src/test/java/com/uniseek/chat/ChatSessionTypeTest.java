package com.uniseek.chat;

import org.junit.Test;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/**
 * ChatSessionType 判别器单元测试
 */
public class ChatSessionTypeTest {

    @Test
    public void shouldTreatNullAsApplicationForBackwardCompatibility() {
        assertTrue(ChatSessionType.isApplication(null));
        assertFalse(ChatSessionType.isDirect(null));
    }

    @Test
    public void shouldRecognizeApplicationSessionType() {
        assertTrue(ChatSessionType.isApplication("application"));
        assertTrue(ChatSessionType.isApplication("APPLICATION"));
        assertFalse(ChatSessionType.isDirect("application"));
    }

    @Test
    public void shouldRecognizeDirectSessionType() {
        assertTrue(ChatSessionType.isDirect("direct"));
        assertTrue(ChatSessionType.isDirect("DIRECT"));
        assertFalse(ChatSessionType.isApplication("direct"));
    }

    @Test
    public void shouldRejectUnknownSessionTypeAsNeitherApplicationNorDirect() {
        assertFalse(ChatSessionType.isApplication("group"));
        assertFalse(ChatSessionType.isDirect("group"));
    }
}
