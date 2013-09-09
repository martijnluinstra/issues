# -*- coding: utf-8 -*-

from flask import render_template, redirect, url_for, request
from flask.ext.login import current_user, login_required
from sqlalchemy.exc import IntegrityError
from issues import app, db, gravatar
from models import Issue, User, Label
from session import is_admin, is_logged_in, admin_required
from forms import AddUserForm, ChangePasswordForm, ConfirmPasswordForm
import json
from api import query_issues_filter_by, create_issue_read_dict

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

    return query_issues_filter_by(**conditions).all()


def labels():
    return Label.query.all()


@app.route('/', methods=['GET'])
@app.route('/<path:path>', methods=['GET'])
def view_frontend(path=None):
    return render_template('index.html',
        page_attributes=u' '.join(page_attributes() + ['issue-tracker-app']),
        user=current_user.to_dict() if is_logged_in() else None,
        current_user=jsonify(current_user.to_dict() if is_logged_in() else None),
        anonymous_gravatar=gravatar(''),
        issues=jsonify([create_issue_read_dict(issue, last_read) for (issue,last_read) in uncompleted_issues()]),
        labels=jsonify([label.to_dict() for label in labels()]))


@app.route('/users', methods=['GET'])
@admin_required
def list_users():
    users = User.query.all()
    return render_template('users.html',
        user=current_user.to_dict() if is_logged_in() else None, 
        users=users)


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


@app.route('/users/<int:user_id>/make-admin', methods=['GET', 'POST'])
@admin_required
def make_admin(user_id):
    form = ConfirmPasswordForm()
    user = User.query.filter_by(id=user_id).first_or_404()
    if form.validate_on_submit():
        if current_user.check_password(form.password.data):
            user.admin = not user.admin
            db.session.commit()
            return redirect(url_for('view_frontend'))
        else: 
            form.password.errors.append('Wrong password')
    return render_template('confirm.html',
        user=current_user.to_dict() if is_logged_in() else None, 
        form=form,
        title='Change Admin Status',
        target=url_for('make_admin', user_id=user_id))


@app.route('/users/change-password', methods=['GET', 'POST'])
@app.route('/users/<int:user_id>/change-password', methods=['GET', 'POST'])
@login_required
def change_password(user_id=None):
    form = ChangePasswordForm()
    if user_id is not None and not is_admin():
        return 'You are not authorised', 403
    if user_id is None:
        user_id = current_user.get_id()
    user = User.query.filter_by(id=user_id).first_or_404()
    if form.validate_on_submit():
        if current_user.check_password(form.current_password.data):
            user.set_password(form.new_password.data)
            db.session.commit()
            return redirect(url_for('view_frontend'))
        else: 
            form.current_password.errors.append('Wrong password')
    return render_template('user_change_password.html',
        form=form,
        user=current_user.to_dict() if is_logged_in() else None,
        user_id=user_id)


@app.route('/idea', methods=['POST'])
def submit_idea():
    if 'idea' in request.form and request.form['idea'].strip():
        description = request.form['idea'].strip()
        # Take the first 50 charcters of the first line of the description, remove trailing spaces and make it the title. 
        title = description.splitlines()[0][:50].strip()
        idea = Issue(title, description, None, True, None, False)
        db.session.add(idea)
        db.session.commit()
        return render_template('thanks.html', error=False, idea=idea)
    return render_template('thanks.html', error=True)
