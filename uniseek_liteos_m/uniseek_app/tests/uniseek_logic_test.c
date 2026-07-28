#include <assert.h>

#include "../include/uniseek_logic.h"

int main(void)
{
    assert(UniseekParseHttpStatus("HTTP/1.1 200 OK\r\n") == 200);
    assert(UniseekParseHttpStatus("HTTP/1.0 204 No Content\r\n") == 204);
    assert(UniseekParseHttpStatus("HTTP/1.1 500 Server Error\r\n") == -1);
    assert(UniseekParseHttpStatus("invalid response") == -1);

    assert(UniseekSelectHealthColor(0, 0, 0) == UNISEEK_HEALTH_RED);
    assert(UniseekSelectHealthColor(1, 0, 0) == UNISEEK_HEALTH_YELLOW);
    assert(UniseekSelectHealthColor(1, 1, 0) == UNISEEK_HEALTH_YELLOW);
    assert(UniseekSelectHealthColor(1, 1, 1) == UNISEEK_HEALTH_GREEN);

    return 0;
}
