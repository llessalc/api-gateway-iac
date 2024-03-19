def lambda_handler(event, context):
    event['response']['answerCorrect'] = False
    if not event['request'].get('privateChallengeParameters', {}).get("challenge"):
        return event
    
    if event['request']['privateChallengeParameters']['challenge'] == event['request']['challengeAnswer']:
        event['response']['answerCorrect'] = True
    return event
