from flask_admin import Admin

...

from fadmin import *
admin = Admin(
    app,
    name='μAdmin',
    template_mode='bootstrap3',
    index_view=MyAdminIndexView(
    url='/fadmin'
    ),
)
from app.models import User, Order
admin.add_view(MyModelView(User, db.session))
admin.add_view(OrderView(Order, db.session))
