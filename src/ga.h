#ifndef GREEN_GA_H
#define GREEN_GA_H

#include <QJsonArray>
#include <QJsonObject>

struct GA_session;

namespace gdk {

QJsonObject convert_amount(GA_session* session, const QJsonObject& input);
QStringList generate_mnemonic(int size);
QJsonObject get_settings(GA_session* session);

} // namespace gdk

#endif // GREEN_GA_H
