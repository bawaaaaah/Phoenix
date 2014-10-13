#include "qdebug.h"
#include "thegamesdb.h"

const QString BASE_URL = "http://thegamesdb.net/api/";
const QString ART_BASE_URL = "http://thegamesdb.net/banners/";
const QStringList EXPRESSIONS = (QStringList() << " "
                                               << "-"
                                               << "\\"
                                               << "/"
                                               << "("
                                               << ")"
                                               << "!"
                                               << "."
                                               << "?"
                                               << ":");

TheGamesDB::TheGamesDB()
{
    state = None;
    manager = new QNetworkAccessManager(this);
    game_data = new GameData();

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processRequest(QNetworkReply*)));
}

TheGamesDB::TheGamesDB (QObject *parent)
    : QObject(parent)
{
    state = None;
    manager = new QNetworkAccessManager(this);
    game_data = new GameData();

    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(processRequest(QNetworkReply*)));
}

TheGamesDB::~TheGamesDB()
{
    qCDebug(phxLibrary) << "delting scraper";
    if (manager)
        manager->deleteLater();
    delete game_data;
}

void TheGamesDB::processRequest(QNetworkReply*)
{
    switch (state) {
        case RequestingId:
            qDebug() << "Requesting Id";
            state = None;
            break;
    }
}

QString TheGamesDB::cleanString(QString string)
{
    for (int i=0; i < EXPRESSIONS.length(); i++) {
        string.remove(EXPRESSIONS.at(i));
    }
    return string.toLower();
}

void TheGamesDB::findXMLGame()
{
    /*QXmlStreamReader reader(reply);

    while (!reader.atEnd()) {
        reader.readNext();
        if (reader.isStartElement()) {
            QString element = reader.name().toString();
            if (element == "id") {
                QString text = reader.readElementText();
                game_data->id = text;
            }
            else if (element == "GameTitle") {
                QString text = reader.readElementText();
                game_data->title= text;
            }
            else if (element == "PlatformID") {
                QString text = reader.readElementText();
                game_data->platform_id = text;
            }
            else if (element == "Platform") {
                QString text = reader.readElementText();
                game_data->platform = text;
            }
            else if (element == "ReleaseDate") {
                QString text = reader.readElementText();
                game_data->release_date = text;

            }
            else if (element == "Overview") {
                QString text = reader.readElementText();
                game_data->overview = text;
            }
            else if (element == "ESRB") {
                QString text = reader.readElementText();
                game_data->esrb = text;
            }
            else if (element == "genre") {
                QString text = reader.readElementText();
                game_data->genre = text;
            }
            else if (element == "Players") {
                QString text = reader.readElementText();
                game_data->players = text;
            }
            else if (element == "Co-op") {
                QString text = reader.readElementText();
                game_data->co_op = text;
            }
            else if (element == "Youtube") {
                QString text = reader.readElementText();
                game_data->youtube = text;
            }
            else if (element == "Publisher") {
                QString text = reader.readElementText();
                game_data->publisher = text;
            }
            else if (element == "Developer") {
                QString text = reader.readElementText();
                game_data->developer = text;
            }
            else if (element == "Rating") {
                QString text = reader.readElementText();
                game_data->rating = text;
            }
            else if (element == "boxart") {
                QStringRef side = reader.attributes().value("side");
                QString text = reader.readElementText();
                if (side == "back" || side == "l/ba")
                    game_data->back_boxart = ART_BASE_URL + text;
                else if (side == "front" || side == "l/fro")
                    game_data->front_boxart = ART_BASE_URL + text;
            }
            else if (element == "clearlogo") {
                QString text = reader.readElementText();
                game_data->clear_logo= text;
            }
        }
    }*/
}


void TheGamesDB::parseXMLforId(QString game_name)
{
    /*QXmlStreamReader reader(reply);

    while (!reader.atEnd()) {
        reader.readNext();
        if (reader.isStartElement()) {
            QString element = reader.name().toString();
            if (element == "id") {
                QString game_id = reader.readElementText();
                game_data->id = game_id;
            }
            else if (element == "GameTitle") {
                QString text = reader.readElementText();
                QString cleaned_title = cleanString(text);
                if (cleaned_title.indexOf(cleanString(game_name)) != -1) {
                    break;
                }
            }
        }
    }*/
}

/*void TheGamesDB::getGame(QString game_id) {
    setUrl(BASE_URL + "Getgame_data->php?id=" + game_id);
    getNetworkReply();
}*/

void TheGamesDB::getGameData(QString &title, QString &system)
{
    // Grab the first data
    state = RequestingId;
    manager->get(QNetworkRequest(QUrl("http://www.google.com"/*BASE_URL + "GetGamesList.php?name=" + title + "&platform=" + system)*/));
}
