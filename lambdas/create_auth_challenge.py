def lambda_handler(event, context):
    user_cpf = event['request']['userAttributes']['custom:cpf']
    event['response']['privateChallengeParameters'] = {"challenge": user_cpf}
    return event
