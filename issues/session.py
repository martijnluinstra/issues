from flask import request, render_template, redirect
from issues import app, db, login_manager
from models import User
from flask.ext.login import login_user, logout_user, login_required

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if current_user is None or current_user.is_anonymous():
            return redirect(url_for('login'))
        if not current_user.admin:
            return 'You are not allowed to enter this realm'
        return f(*args, **kwargs)
    return decorated_function

@login_manager.user_loader
def load_user(userid):
    return User.query.get(userid)

@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == 'POST':
        user = User.query.filter_by(email = request.form['email']).first()
        if user is None:
            error = 'Invalid email'
        elif not user.check_password(request.form['password']):
            error = 'Invalid password'
        else:
            login_user(user)
            return 'Logged in successfully.' #redirect(request.args.get('next')) or 
    return render_template('login.html', error=error)

@app.route('/logout', methods=['GET'])
@login_required
def logout():
    logout_user()
    return 'You were logged out'

@app.route('/', methods=['GET'])
@login_required
def haai():
    return 'Hi!'