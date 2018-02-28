from flask import render_template, redirect, request, url_for, flash, session, abort, current_app
from flask_login import login_required, login_user, logout_user, current_user
from flask_admin import BaseView, AdminIndexView, expose
from flask_admin.contrib.sqla import ModelView

class MyModelView(ModelView):
    def is_accessible(self):
       return current_user.is_administrator()
    can_create = False
    can_edit = True
    can_delete = False

class MyBaseView(BaseView):
    def is_accessible(self):
       return current_user.is_administrator()

class MyAdminIndexView(AdminIndexView):
    def is_accessible(self):
       return current_user.is_administrator()

    def inaccessible_callback(self, name, **kwargs):
        # redirect to login page if user doesn't have access
        return redirect(url_for('auth.login', next=request.url))

    @expose('/')
    def index(self):
        return self.render('fadmin.html')

        if not current_user.is_authenticated:
            return redirect(url_for('auth.login'))
        return super(MyAdminIndexView, self).index()

    @expose('/test1')
    def test1(self):
        return self.render('fadmin.html')

class OrderView(MyModelView):
    form_columns = ['comment', 'owner']
