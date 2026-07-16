import random

from config import FAVORITE_COUNT
from sql_output import SQLWriter
from time_utils import weighted_random_time


FAVORITE_COLUMNS = ["id", "user_id", "task_id", "create_time"]


def generate_favorites(writer: SQLWriter, seeker_ids: list, task_ids: list):
    writer.write_comment(f"收藏表（{FAVORITE_COUNT} 条记录）")
    writer.begin_insert("favorite", FAVORITE_COLUMNS)

    generated = set()
    max_attempts = FAVORITE_COUNT * 5
    attempts = 0
    count = 0

    while count < FAVORITE_COUNT and attempts < max_attempts:
        attempts += 1
        uid = random.choice(seeker_ids)
        tid = random.choice(task_ids)
        key = (uid, tid)
        if key in generated:
            continue
        generated.add(key)
        fav_id = writer.next_id("favorite")
        create_time = weighted_random_time()
        writer.add_row([fav_id, uid, tid, format_dt(create_time)])
        count += 1


def format_dt(dt):
    return dt.strftime("%Y-%m-%d %H:%M:%S")
