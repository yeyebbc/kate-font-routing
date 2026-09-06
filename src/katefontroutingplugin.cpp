// SPDX-License-Identifier: MIT

#include <KPluginFactory>
#include <KTextEditor/MainWindow>
#include <KTextEditor/Plugin>

#include <QFontDatabase>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

namespace
{
const QStringList HanFallbackFonts{QStringLiteral("Maple Mono CN")};
const QStringList EmojiFallbackFonts{QStringLiteral("Noto Color Emoji")};

bool fontFamilyExists(const QString &family)
{
    const auto installedFamilies = QFontDatabase::families();
    return installedFamilies.contains(family, Qt::CaseInsensitive);
}
}

class KateFontRoutingPlugin final : public KTextEditor::Plugin
{
    Q_OBJECT

public:
    explicit KateFontRoutingPlugin(QObject *parent, const QVariantList &)
        : KTextEditor::Plugin(parent)
        , m_previousHanFallbackFonts(QFontDatabase::applicationFallbackFontFamilies(QChar::Script_Han))
        , m_previousEmojiFallbackFonts(QFontDatabase::applicationEmojiFontFamilies())
    {
        QFontDatabase::setApplicationFallbackFontFamilies(QChar::Script_Han, HanFallbackFonts);
        QFontDatabase::setApplicationEmojiFontFamilies(EmojiFallbackFonts);

        if (!fontFamilyExists(HanFallbackFonts.constFirst())) {
            m_missingFonts.append(HanFallbackFonts.constFirst());
        }
        if (!fontFamilyExists(EmojiFallbackFonts.constFirst())) {
            m_missingFonts.append(EmojiFallbackFonts.constFirst());
        }
    }

    ~KateFontRoutingPlugin() override
    {
        // Restore what was present before this plugin loaded, but do not
        // overwrite a newer change made by another component.
        if (QFontDatabase::applicationFallbackFontFamilies(QChar::Script_Han) == HanFallbackFonts) {
            QFontDatabase::setApplicationFallbackFontFamilies(QChar::Script_Han, m_previousHanFallbackFonts);
        }
        if (QFontDatabase::applicationEmojiFontFamilies() == EmojiFallbackFonts) {
            QFontDatabase::setApplicationEmojiFontFamilies(m_previousEmojiFallbackFonts);
        }
    }

    QObject *createView(KTextEditor::MainWindow *mainWindow) override
    {
        auto *view = new QObject(mainWindow);

        if (!m_missingFonts.isEmpty()) {
            QVariantMap message;
            message.insert(QStringLiteral("category"), QStringLiteral("Font Routing"));
            message.insert(QStringLiteral("type"), QStringLiteral("Warning"));
            message.insert(
                QStringLiteral("text"),
                QStringLiteral("Font Routing cannot find: %1. Install the font and restart Kate.")
                    .arg(m_missingFonts.join(QStringLiteral(", "))));
            mainWindow->showMessage(message);
        }

        return view;
    }

private:
    const QStringList m_previousHanFallbackFonts;
    const QStringList m_previousEmojiFallbackFonts;
    QStringList m_missingFonts;
};

K_PLUGIN_CLASS_WITH_JSON(KateFontRoutingPlugin, "katefontroutingplugin.json")

#include "katefontroutingplugin.moc"
