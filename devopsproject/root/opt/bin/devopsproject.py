from flask import Flask, request
from flask_restful import Resource, Api
from sqlalchemy import create_engine
import json

db_connect = create_engine('sqlite:///sample.db')
conn = db_connect.connect()
query = conn.execute("select name from sqlite_master where type = 'table'")
print (query.cursor.fetchall())
query = conn.execute("create table if not exists messages (name text, messages text)")
query = conn.execute("select name from sqlite_master where type = 'table'")
print (query.cursor.fetchall())
query = conn.execute("select * from messages")
print (query.cursor.fetchall())
app = Flask(__name__)
api = Api(app)
conn.close()

def check_palindrome(message):
    if message == message[::-1]:
        print(message + " is a palindrome")
        return "true"
    else:
        print(message + " is not a palindrome")
        return "false"

@app.route('/', methods = ['GET'])
def health_check():
    return "done"

@app.route('/messages', methods = ['POST', 'GET'])
def message_create():
    print(request.json)
    conn_post = db_connect.connect()
    if request.method == 'POST':
        query = conn_post.execute("insert into messages values ('"+request.json['name']+"','"+request.json['messages']+"')")
        print(query)
        return "Hello - your message is posted"
    elif request.method == 'GET':
        query = conn_post.execute("select * from messages")
        json_contents = [dict((query.cursor.description[i][0], value) for i,value in enumerate(row)) for row in query.cursor.fetchall()]
        print(json_contents)
        return json.dumps(json_contents)

@app.route('/message/<name>', methods = ['GET', 'DELETE'])
def message_validate_palindrome(name):
    conn_get = db_connect.connect()
    if request.method == 'GET':
        query = conn_get.execute("select * from messages where name='"+name+"'")
        json_contents = [dict((query.cursor.description[i][0], value) for i,value in enumerate(row)) for row in query.cursor.fetchall()]
        print(json_contents)
        check_palindrome(json_contents[0]['messages'])
        for d in json_contents:
            d['palindrome'] = check_palindrome(d['messages'])
        print(json_contents)
        return json.dumps(json_contents)
    elif request.method == 'DELETE':
        query = conn_get.execute("delete from messages where name='"+name+"'")
        query = conn_get.execute("select * from messages")
        print(query.cursor.fetchall())
        return "deleted"

if __name__ == '__main__':
     app.run(port='5002',host='0.0.0.0')

