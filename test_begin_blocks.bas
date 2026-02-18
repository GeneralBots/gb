DESCRIPTION "Test BEGIN TALK and BEGIN MAIL preprocessing"

' Test BEGIN TALK block
BEGIN TALK
This is line 1 with ${variable}
This is line 2 with ${anotherVariable}
END TALK

' Test BEGIN MAIL block
BEGIN MAIL test@example.com
Subject: Test Email Subject

This is the body line 1
This is the body line 2 with ${data}
END MAIL

TALK "Test complete"
