# streaming_worker.py
from kafka import KafkaConsumer
from time import sleep
import json

def process_message(message):
    print ("%d:%d: v=%s" % (message.partition,
                              message.offset,
                              message.value))
    
if __name__ == "__main__":
    print("starting streaming consumer app")
    consumer = KafkaConsumer(
        'price-sink-u19-1641046207-11006669201913062486',
        bootstrap_servers=["localhost:9092"],
        group_id="4504947f06a3f06e857132017c61dca3bddcbbf526301a944ed06323acce0080",
        value_deserializer = lambda m: json.loads(m.decode('utf-8')),
    )
    
    for message in consumer:
        process_message(message)

