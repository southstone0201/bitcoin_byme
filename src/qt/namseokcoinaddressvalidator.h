// Copyright (c) 2011-2020 The Namseokcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef NAMSEOKCOIN_QT_NAMSEOKCOINADDRESSVALIDATOR_H
#define NAMSEOKCOIN_QT_NAMSEOKCOINADDRESSVALIDATOR_H

#include <QValidator>

/** Base58 entry widget validator, checks for valid characters and
 * removes some whitespace.
 */
class NamseokcoinAddressEntryValidator : public QValidator
{
    Q_OBJECT

public:
    explicit NamseokcoinAddressEntryValidator(QObject *parent);

    State validate(QString &input, int &pos) const override;
};

/** Namseokcoin address widget validator, checks for a valid namseokcoin address.
 */
class NamseokcoinAddressCheckValidator : public QValidator
{
    Q_OBJECT

public:
    explicit NamseokcoinAddressCheckValidator(QObject *parent);

    State validate(QString &input, int &pos) const override;
};

#endif // NAMSEOKCOIN_QT_NAMSEOKCOINADDRESSVALIDATOR_H
