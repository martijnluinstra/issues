# -*- coding: utf-8 -*-

from flask import render_template, redirect, url_for
from flask.ext.login import current_user, login_required
from sqlalchemy.exc import IntegrityError
from issues import app, db
from models import Issue, User
from session import is_admin, is_logged_in
from forms import AddUserForm, ChangePasswordForm
import json

def jsonify(data):
    return unicode(json.dumps(data, indent=2, ensure_ascii=False))

def page_attributes():
    attributes = []

    if is_logged_in():
        attributes.append(u'user-logged-in')
    else:
        attributes.append(u'user-not-logged-in')

    if is_admin():
        attributes.append(u'user-is-admin')
    else:
        attributes.append(u'user-is-not-admin')

    return attributes

def uncompleted_issues():
    conditions = {'completed': None}

    # Only show public issues to non-admins
    if not is_admin():
        conditions['public'] = True

    return Issue.query.filter_by(**conditions).all()

@app.route('/', methods=['GET'])
@app.route('/<path:path>', methods=['GET'])
def view_frontend(path=None):
    return render_template('index.html',
        page_attributes=u' '.join(page_attributes()),
        user_name=unicode(current_user.name) if is_logged_in() else None,
        current_user=jsonify(current_user.to_dict() if is_logged_in() else None),
        issues=jsonify([issue.to_dict() for issue in uncompleted_issues()]))

@app.route('/users/add', methods=['GET', 'POST'])
def add_user():
    form = AddUserForm()
    if form.validate_on_submit():
        try:
            user = User(form.name.data, form.password.data, form.email.data)
            db.session.add(user)
            db.session.commit()
            return redirect(url_for('view_frontend'))
        except IntegrityError:
            form.email.errors.append('Email address is not unique')
    return render_template('user_add.html', form=form)

@app.route('/users/change-password', methods=['GET', 'POST'])
@login_required
def change_password():
    form = ChangePasswordForm()
    if form.validate_on_submit():
        if current_user.check_password(form.current_password.data):
            user = User.query.filter_by(id=current_user.get_id()).first_or_404()
            user.set_password(form.new_password.data)
            db.session.commit()
            return redirect(url_for('view_frontend'))
        else: 
            form.current_password.errors.append('Wrong password')
    return render_template('user_change_password.html', form=form)

