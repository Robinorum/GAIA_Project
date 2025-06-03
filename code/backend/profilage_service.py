import pika
import json

ALL_MOVEMENTS = [
    "Abstraction", "Art déco", "Art naïf", "Art nouveau", "Baroque", "Byzantin",
    "Calligraphie", "Cubisme", "Dadaïsme", "Expressionnisme", "Fauvisme", "Hyperréalisme",
    "Impressionnisme", "Inconnu", "Maniérisme", "Néoclassicisme", "Pop art", "Post-impressionnisme",
    "Primitif", "Pré-raphaélisme", "Renaissance", "Rococo", "Romantisme", "Réalisme", "Surréalisme",
    "Symbolisme"
]

def init_profile():
    return {m: 1.0 for m in ALL_MOVEMENTS}

def update_profile(profile, movement, action, alpha=0.1):
    if movement not in profile:
        print(f"[WARN] Unknown movement : {movement}.")
        profile[movement] = 0.0

    for m in profile:
        if m == movement:
            if action == "like":
                profile[m] += alpha * (1 - profile[m])
            elif action == "dislike":
                profile[m] -= alpha * profile[m]
        else:
            profile[m] *= (1 - alpha * 0.2)

    total = sum(profile.values())
    if total > 0:
        profile = {k: round(v / total, 4) for k, v in profile.items()}

    return profile

def callback(ch, method, properties, body):
    try:
        data = json.loads(body)
        uid = data.get("uid")
        movement = data.get("movement")
        action = data.get("action")
        previous_profile = data.get("previous_profile", {}) or init_profile()

        new_profile = update_profile(previous_profile, movement, action)

        response = {
            "uid": uid,
            "new_profile": new_profile
        }

        ch.basic_publish(
            exchange='',
            routing_key='profiling_completed',
            body=json.dumps(response)
        )
        print(f"Updated profile for {uid}")
    except Exception as e:
        print(f"Error while updating : {e}")

def start_worker():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
    channel = connection.channel()

    channel.queue_declare(queue='profiling_requested')
    channel.queue_declare(queue='profiling_completed')

    channel.basic_consume(queue='profiling_requested', on_message_callback=callback, auto_ack=True)
    print("Listening messages...")
    channel.start_consuming()

if __name__ == "__main__":
    start_worker()
