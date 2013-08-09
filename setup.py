from issues import db
from issues.models import User, Issue, Comment, Label
from datetime import datetime

# Create the database
db.create_all()

# Create some users
u_jelmer = User('Jelmer', 'test', 'jelmer@ikhoefgeen.nl', True)
u_martijn = User('Martijn','cover', 'martijnluinstra@gmail.com', True)
u_dummy = User('Dummy', 'dummy', 'no-reply@ikhoefgeen.nl')

db.session.add(u_jelmer)
db.session.add(u_martijn)
db.session.add(u_dummy)
db.session.commit()

issue_1 = Issue('Issue 1', 'Some test issue', u_jelmer.id, False, datetime.now())
issue_2 = Issue('Issue 2', 'Some other test issue', u_martijn.id, True, datetime.now())
issue_3 = Issue('Issue 3', 'Another test issue', u_dummy.id, True, datetime.now())

db.session.add(issue_1)
db.session.add(issue_2)
db.session.add(issue_3)
db.session.commit()

db.session.add(Comment(issue_1.id, u_jelmer.id, "Hello World"))
db.session.add(Comment(issue_1.id, u_jelmer.id, "This is another comment"))
db.session.add(Comment(issue_1.id, u_jelmer.id, "Am I boring you already?"))
db.session.add(Comment(issue_1.id, u_dummy.id, "Yes Jelmer, you are!"))
db.session.commit()


label_1 = Label("Label1", "#ff0000")
label_2 = Label("Label2", "#00ff00")
label_3 = Label("Label3", "#0000ff")
label_4 = Label("Label4", "#000000")

db.session.add(label_1)
db.session.add(label_2)
db.session.add(label_3)
db.session.add(label_4)
db.session.commit()

issue_1.labels.append(label_1)
issue_1.labels.append(label_2)
issue_2.labels.append(label_1)
issue_2.labels.append(label_3)
issue_3.labels.append(label_1)
issue_3.labels.append(label_3)
issue_3.labels.append(label_4)
db.session.commit()