from flask import request, render_template, redirect, url_for
from issues import app, db, login_manager
from models import User
from flask.ext.login import login_user, logout_user, login_required, current_user
from functools import wraps

def is_logged_in():
    return current_user is not None and not current_user.is_anonymous()

def is_admin():
    return is_logged_in() and current_user.admin

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated():
            return current_app.login_manager.unauthorized()
        elif not is_admin():
            return 'You are not allowed perform this action!', 403
        return f(*args, **kwargs)
    return decorated_function

def api_admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not is_admin():
            return 'You are not allowed perform this action!', 403
        return f(*args, **kwargs)
    return decorated_function

def api_login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated():
            return 'You are not allowed perform this action!', 403
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
            return redirect(request.args.get('next')) or redirect(url_for('view_frontend'))

    return render_template('login.html', error=error)

@app.route('/logout', methods=['GET'])
@login_required
def logout():
    logout_user()
    return redirect(url_for('view_frontend'))
