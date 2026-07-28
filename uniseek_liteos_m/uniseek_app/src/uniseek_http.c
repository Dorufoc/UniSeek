#include <stdio.h>
#include <string.h>

#include "lwip/inet.h"
#include "lwip/sockets.h"
#include "uniseek_config.h"
#include "uniseek_http.h"
#include "uniseek_logic.h"

static int UniseekSendAll(int socketFd, const char *data, unsigned int length)
{
    int sent;
    unsigned int offset = 0;

    while (offset < length) {
        sent = send(socketFd, data + offset, length - offset, 0);
        if (sent <= 0) {
            return -1;
        }
        offset += (unsigned int)sent;
    }
    return 0;
}

int UniseekHttpPost(double temperature, double humidity, int *httpStatus)
{
    char body[96];
    char request[320];
    char response[128] = {0};
    struct sockaddr_in server = {0};
    struct timeval timeout = {5, 0};
    int socketFd;
    int received;
    int bodyLength;
    int requestLength;
    int status;

    if (httpStatus == NULL) {
        return -1;
    }
    *httpStatus = 0;
    bodyLength = snprintf(body, sizeof(body), "{\"temperature\":%.2f,\"humidity\":%.2f}", temperature, humidity);
    if (bodyLength < 0 || bodyLength >= (int)sizeof(body)) {
        return -1;
    }
    requestLength = snprintf(request, sizeof(request),
        "POST %s HTTP/1.1\r\nHost: %s:%d\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s",
        UNISEEK_API_PATH, UNISEEK_SERVER_IP, UNISEEK_SERVER_PORT, bodyLength, body);
    if (requestLength < 0 || requestLength >= (int)sizeof(request)) {
        return -1;
    }
    socketFd = socket(AF_INET, SOCK_STREAM, 0);
    if (socketFd < 0) {
        return -1;
    }
    (void)setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    (void)setsockopt(socketFd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
    server.sin_family = AF_INET;
    server.sin_port = htons(UNISEEK_SERVER_PORT);
    server.sin_addr.s_addr = inet_addr(UNISEEK_SERVER_IP);
    if (connect(socketFd, (struct sockaddr *)&server, sizeof(server)) < 0 ||
        UniseekSendAll(socketFd, request, (unsigned int)requestLength) != 0) {
        lwip_close(socketFd);
        return -1;
    }
    received = recv(socketFd, response, sizeof(response) - 1, 0);
    lwip_close(socketFd);
    if (received <= 0) {
        return -1;
    }
    status = UniseekParseHttpStatus(response);
    if (status < 0) {
        return -1;
    }
    *httpStatus = status;
    return 0;
}
